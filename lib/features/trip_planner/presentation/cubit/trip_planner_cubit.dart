import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/route_finder.dart';
import '../../domain/trip_repository.dart';
import 'trip_planner_state.dart';

class TripPlannerCubit extends Cubit<TripPlannerState> {
  TripPlannerCubit(this._repository, this._routeFinder)
    : super(const TripPlannerLoading());

  final TripRepository _repository;
  final RouteFinder _routeFinder;

  /// Loads the trip data. Also serves as the retry action.
  Future<void> load() async {
    emit(const TripPlannerLoading());
    try {
      final data = await _repository.loadTripData();
      emit(
        TripPlannerReady(cities: data.cities, connections: data.connections),
      );
    } on Failure catch (failure) {
      emit(TripPlannerLoadFailure(failure));
    }
  }

  void selectDeparture(String? city) {
    if (state case final TripPlannerReady ready) {
      _select(ready, departure: city, destination: ready.destination);
    }
  }

  void selectDestination(String? city) {
    if (state case final TripPlannerReady ready) {
      _select(ready, departure: ready.departure, destination: city);
    }
  }

  void _select(
    TripPlannerReady ready, {
    required String? departure,
    required String? destination,
  }) {
    if (departure == ready.departure && destination == ready.destination) {
      return;
    }
    emit(
      TripPlannerReady(
        cities: ready.cities,
        connections: ready.connections,
        departure: departure,
        destination: destination,
        routeResult: _findRoute(ready, departure, destination),
      ),
    );
  }

  RouteResult _findRoute(
    TripPlannerReady ready,
    String? departure,
    String? destination,
  ) {
    if (departure == null || destination == null || departure == destination) {
      return const RouteNoneSelected();
    }
    final route = _routeFinder.findCheapestRoute(
      connections: ready.connections,
      from: departure,
      to: destination,
    );
    return route == null ? const RouteNotFound() : RouteFound(route);
  }
}
