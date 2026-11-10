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

  /// The last selection, kept outside the state so that it survives the
  /// loading and failure states of a reload.
  ({String? departure, String? destination}) _selection = (
    departure: null,
    destination: null,
  );

  /// Loads the trip data. Also serves as the retry action, and keeps the
  /// selected cities if they are still in the data.
  Future<void> load() async {
    if (state case TripPlannerReady(:final departure, :final destination)) {
      _selection = (departure: departure, destination: destination);
    }
    emit(const TripPlannerLoading());
    try {
      final data = await _repository.loadTripData();
      final names = {for (final city in data.cities) city.name};
      String? stillListed(String? city) => names.contains(city) ? city : null;
      emit(
        _withSelection(
          TripPlannerReady(
            cities: data.cities,
            connections: data.connections,
            imagesUnavailable: data.imagesUnavailable,
          ),
          departure: stillListed(_selection.departure),
          destination: stillListed(_selection.destination),
        ),
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
    emit(_withSelection(ready, departure: departure, destination: destination));
  }

  TripPlannerReady _withSelection(
    TripPlannerReady ready, {
    required String? departure,
    required String? destination,
  }) {
    _selection = (departure: departure, destination: destination);
    return TripPlannerReady(
      cities: ready.cities,
      connections: ready.connections,
      departure: departure,
      destination: destination,
      routeResult: _findRoute(ready, departure, destination),
      imagesUnavailable: ready.imagesUnavailable,
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
