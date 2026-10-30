import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/city.dart';
import '../../domain/connection.dart';
import '../../domain/trip_route.dart';

sealed class TripPlannerState extends Equatable {
  const TripPlannerState();

  @override
  List<Object?> get props => [];
}

final class TripPlannerLoading extends TripPlannerState {
  const TripPlannerLoading();
}

final class TripPlannerLoadFailure extends TripPlannerState {
  const TripPlannerLoadFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class TripPlannerReady extends TripPlannerState {
  const TripPlannerReady({
    required this.cities,
    required this.connections,
    this.departure,
    this.destination,
    this.routeResult = const RouteNoneSelected(),
  });

  final List<City> cities;
  final List<Connection> connections;
  final String? departure;
  final String? destination;
  final RouteResult routeResult;

  bool get isSameCity => departure != null && departure == destination;

  @override
  List<Object?> get props => [
    cities,
    connections,
    departure,
    destination,
    routeResult,
  ];
}

sealed class RouteResult extends Equatable {
  const RouteResult();

  @override
  List<Object?> get props => [];
}

/// There is nothing to search for yet: a city is missing, or both are the same.
final class RouteNoneSelected extends RouteResult {
  const RouteNoneSelected();
}

final class RouteFound extends RouteResult {
  const RouteFound(this.route);

  final TripRoute route;

  @override
  List<Object?> get props => [route];
}

final class RouteNotFound extends RouteResult {
  const RouteNotFound();
}
