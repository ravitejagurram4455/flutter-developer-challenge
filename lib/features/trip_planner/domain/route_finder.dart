import 'connection.dart';
import 'trip_route.dart';

/// Thrown when a connection has a negative price, because the cheapest route
/// is then not something a [RouteFinder] can answer reliably.
class NegativePriceException implements Exception {
  const NegativePriceException(this.connection);

  final Connection connection;

  @override
  String toString() =>
      'NegativePriceException: ${connection.from} -> ${connection.to} '
      'costs ${connection.priceInCents} cents';
}

abstract interface class RouteFinder {
  /// Returns the cheapest route from [from] to [to].
  ///
  /// Returns null when there is no route to take: the cities are not connected,
  /// either one is unknown, or [from] and [to] are the same city.
  ///
  /// Throws [NegativePriceException] if any connection has a negative price.
  TripRoute? findCheapestRoute({
    required List<Connection> connections,
    required String from,
    required String to,
  });
}
