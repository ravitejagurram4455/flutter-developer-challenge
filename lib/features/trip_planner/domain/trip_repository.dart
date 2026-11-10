import 'package:equatable/equatable.dart';

import 'city.dart';
import 'connection.dart';

class TripData extends Equatable {
  const TripData({
    required this.cities,
    required this.connections,
    this.imagesUnavailable = false,
  });

  final List<City> cities;
  final List<Connection> connections;

  /// True when the city images could not be loaded. Routes still work.
  final bool imagesUnavailable;

  @override
  List<Object?> get props => [cities, connections, imagesUnavailable];
}

abstract interface class TripRepository {
  /// Loads every city and connection.
  ///
  /// Throws a `Failure` from `core/error/failures.dart` if the connections
  /// cannot be loaded. Missing city images are reported in [TripData] instead.
  Future<TripData> loadTripData();
}
