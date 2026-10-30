import 'package:collection/collection.dart';

import 'connection.dart';
import 'route_finder.dart';
import 'trip_route.dart';

/// Dijkstra's algorithm over the directed graph of connections.
///
/// Runs in O((V + E) log E) time and O(V + E) space for V cities and
/// E connections. Routes are compared by price, then by number of legs, so
/// ties resolve to the simpler route and zero-price cycles cannot be re-entered.
class DijkstraRouteFinder implements RouteFinder {
  const DijkstraRouteFinder();

  @override
  TripRoute? findCheapestRoute({
    required List<Connection> connections,
    required String from,
    required String to,
  }) {
    final departuresByCity = <String, List<Connection>>{};
    for (final connection in connections) {
      if (connection.priceInCents < 0) {
        throw NegativePriceException(connection);
      }
      (departuresByCity[connection.from] ??= []).add(connection);
    }

    if (from == to) return null;

    final best = <String, _Label>{from: _Label(city: from, price: 0, legs: 0)};
    final arrivedBy = <String, Connection>{};
    final queue = PriorityQueue<_Label>()..add(best[from]!);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      // A better label for this city was queued after this one.
      if (current != best[current.city]) continue;
      if (current.city == to) return _buildRoute(arrivedBy, from, to);

      for (final connection
          in departuresByCity[current.city] ?? const <Connection>[]) {
        final candidate = _Label(
          city: connection.to,
          price: current.price + connection.priceInCents,
          legs: current.legs + 1,
        );
        final known = best[connection.to];
        if (known == null || candidate.compareTo(known) < 0) {
          best[connection.to] = candidate;
          arrivedBy[connection.to] = connection;
          queue.add(candidate);
        }
      }
    }
    return null;
  }

  TripRoute _buildRoute(
    Map<String, Connection> arrivedBy,
    String from,
    String to,
  ) {
    final legs = <Connection>[];
    for (var city = to; city != from; city = legs.last.from) {
      legs.add(arrivedBy[city]!);
    }
    return TripRoute(legs.reversed.toList());
  }
}

class _Label implements Comparable<_Label> {
  const _Label({required this.city, required this.price, required this.legs});

  final String city;
  final int price;
  final int legs;

  @override
  int compareTo(_Label other) {
    final byPrice = price.compareTo(other.price);
    return byPrice != 0 ? byPrice : legs.compareTo(other.legs);
  }
}
