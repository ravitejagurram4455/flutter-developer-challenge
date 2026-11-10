import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/connection.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/dijkstra_route_finder.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/route_finder.dart';

const _origin = Coordinates(latitude: 0, longitude: 0);

Connection _leg(String from, String to, int priceInCents) => Connection(
  from: from,
  to: to,
  priceInCents: priceInCents,
  fromCoordinates: _origin,
  toCoordinates: _origin,
);

void main() {
  const finder = DijkstraRouteFinder();

  List<Connection>? find(List<Connection> connections, String from, String to) {
    return finder
        .findCheapestRoute(connections: connections, from: from, to: to)
        ?.legs;
  }

  test('returns a direct connection', () {
    final direct = _leg('A', 'B', 100);

    expect(find([direct], 'A', 'B'), [direct]);
  });

  test('prefers a cheaper multi-leg route over an expensive direct one', () {
    final ab = _leg('A', 'B', 100);
    final bc = _leg('B', 'C', 100);

    expect(find([_leg('A', 'C', 500), ab, bc], 'A', 'C'), [ab, bc]);
  });

  test('prefers a cheaper direct route over a multi-leg one', () {
    final direct = _leg('A', 'C', 150);

    expect(find([_leg('A', 'B', 100), _leg('B', 'C', 100), direct], 'A', 'C'), [
      direct,
    ]);
  });

  test('uses the cheapest of several parallel connections', () {
    final cheap = _leg('A', 'B', 100);

    expect(find([_leg('A', 'B', 300), cheap, _leg('A', 'B', 200)], 'A', 'B'), [
      cheap,
    ]);
  });

  test('treats connections as directed', () {
    final connections = [_leg('A', 'B', 100)];

    expect(find(connections, 'B', 'A'), isNull);
  });

  test('uses the price of the direction being travelled', () {
    final there = _leg('A', 'B', 100);
    final back = _leg('B', 'A', 900);

    expect(find([there, back], 'A', 'B'), [there]);
    expect(find([there, back], 'B', 'A'), [back]);
  });

  test('terminates on cycles and still finds the route', () {
    final ab = _leg('A', 'B', 100);
    final bc = _leg('B', 'C', 100);

    expect(find([ab, _leg('B', 'A', 100), bc, _leg('C', 'B', 1)], 'A', 'C'), [
      ab,
      bc,
    ]);
  });

  test('returns null for disconnected cities', () {
    final connections = [_leg('A', 'B', 100), _leg('C', 'D', 100)];

    expect(find(connections, 'A', 'D'), isNull);
  });

  test('returns null when either city is unknown', () {
    final connections = [_leg('A', 'B', 100)];

    expect(find(connections, 'A', 'Unknown'), isNull);
    expect(find(connections, 'Unknown', 'B'), isNull);
  });

  test('returns null when there are no connections', () {
    expect(find(const [], 'A', 'B'), isNull);
  });

  test('accepts zero prices', () {
    final ab = _leg('A', 'B', 0);
    final bc = _leg('B', 'C', 0);

    final route = finder.findCheapestRoute(
      connections: [_leg('A', 'C', 1), ab, bc],
      from: 'A',
      to: 'C',
    );

    expect(route?.legs, [ab, bc]);
    expect(route?.totalPriceInCents, 0);
  });

  test('terminates on a cycle of zero prices', () {
    final connections = [
      _leg('A', 'B', 0),
      _leg('B', 'A', 0),
      _leg('B', 'C', 5),
    ];

    expect(find(connections, 'A', 'C')?.length, 2);
  });

  test('returns null for the same departure and destination', () {
    final connections = [_leg('A', 'B', 100), _leg('B', 'A', 100)];

    expect(find(connections, 'A', 'A'), isNull);
  });

  test('breaks a price tie in favour of fewer legs', () {
    final direct = _leg('A', 'C', 200);

    expect(find([_leg('A', 'B', 100), _leg('B', 'C', 100), direct], 'A', 'C'), [
      direct,
    ]);
  });

  test('throws on a negative price, even on an unrelated connection', () {
    final negative = _leg('X', 'Y', -1);

    expect(
      () => find([_leg('A', 'B', 100), negative], 'A', 'B'),
      throwsA(
        isA<NegativePriceException>().having(
          (e) => e.connection,
          'connection',
          negative,
        ),
      ),
    );
  });

  test('totals legs in exact cents', () {
    final route = finder.findCheapestRoute(
      connections: [_leg('A', 'B', 10), _leg('B', 'C', 20)],
      from: 'A',
      to: 'C',
    );

    expect(route?.totalPriceInCents, 30);
  });

  test('finds a several-leg route through a larger network', () {
    final cheapest = [
      _leg('A', 'C', 200),
      _leg('C', 'F', 100),
      _leg('F', 'E', 150),
      _leg('E', 'H', 100),
      _leg('H', 'J', 50),
    ];
    final connections = [
      _leg('A', 'J', 900),
      _leg('A', 'B', 100),
      _leg('B', 'D', 400),
      _leg('D', 'J', 300),
      _leg('B', 'C', 150),
      _leg('C', 'D', 500),
      _leg('D', 'G', 50),
      _leg('G', 'J', 400),
      _leg('F', 'A', 10),
      _leg('E', 'C', 10),
      _leg('H', 'B', 10),
      _leg('F', 'G', 500),
      _leg('E', 'J', 300),
      _leg('J', 'A', 1),
      _leg('K', 'L', 1),
      ...cheapest,
    ];

    final route = finder.findCheapestRoute(
      connections: connections,
      from: 'A',
      to: 'J',
    );

    expect(route?.legs, cheapest);
    expect(route?.totalPriceInCents, 600);
  });
}
