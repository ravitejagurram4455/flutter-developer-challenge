import 'package:equatable/equatable.dart';

import 'city.dart';
import 'connection.dart';

class TripData extends Equatable {
  const TripData({required this.cities, required this.connections});

  final List<City> cities;
  final List<Connection> connections;

  @override
  List<Object?> get props => [cities, connections];
}

abstract interface class TripRepository {
  /// Loads every city and connection.
  ///
  /// Throws a `Failure` from `core/error/failures.dart` if that is not possible.
  Future<TripData> loadTripData();
}
