import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/connection.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/trip_route.dart';
import 'package:flutter_tui_challenge/features/trip_planner/presentation/widgets/route_path.dart';

Coordinates _at(double longitude) =>
    Coordinates(latitude: 0, longitude: longitude);

Connection _leg(double fromLongitude, double toLongitude) => Connection(
  from: '$fromLongitude',
  to: '$toLongitude',
  priceInCents: 100,
  fromCoordinates: _at(fromLongitude),
  toCoordinates: _at(toLongitude),
);

List<double> _longitudes(List<Connection> legs) => [
  for (final point in routePath(TripRoute(legs))) point.longitude,
];

void main() {
  test('leaves a route that does not cross the antimeridian unchanged', () {
    expect(_longitudes([_leg(-0.2, -73.9), _leg(-73.9, -118.2)]), [
      -0.2,
      -73.9,
      -73.9,
      -118.2,
    ]);
  });

  test('draws a leg across the Pacific the short way', () {
    expect(_longitudes([_leg(-118, 140)]), [-118, -220]);
  });

  test('draws the same leg the short way in the other direction', () {
    expect(_longitudes([_leg(140, -118)]), [-220, -118]);
  });

  test('keeps a multi-leg route continuous across the antimeridian', () {
    final longitudes = _longitudes([
      _leg(-0.2, -118),
      _leg(-118, 140),
      _leg(140, 151),
    ]);

    expect(longitudes, [-0.2, -118, -118, -220, -220, -209]);
  });

  test('keeps the middle of the path within -180 to 180', () {
    final longitudes = _longitudes([
      _leg(170, -170),
      _leg(-170, -150),
      _leg(-150, -130),
    ]);

    expect(longitudes, [-190, -170, -170, -150, -150, -130]);
  });

  test('keeps latitudes', () {
    const leg = Connection(
      from: 'A',
      to: 'B',
      priceInCents: 100,
      fromCoordinates: Coordinates(latitude: 34, longitude: -118),
      toCoordinates: Coordinates(latitude: 35.6, longitude: 140),
    );

    expect(routePath(const TripRoute([leg])), const [
      Coordinates(latitude: 34, longitude: -118),
      Coordinates(latitude: 35.6, longitude: -220),
    ]);
  });

  test('returns nothing for a route with no legs', () {
    expect(routePath(const TripRoute([])), isEmpty);
  });
}
