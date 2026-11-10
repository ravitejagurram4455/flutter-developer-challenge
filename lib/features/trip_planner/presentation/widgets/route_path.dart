import 'dart:math';

import '../../domain/connection.dart';
import '../../domain/trip_route.dart';

/// The start and end of every leg of [route], in travel order, with longitudes
/// adjusted so the map draws each leg the short way.
///
/// A longitude may move by whole turns of 360°, so consecutive points are
/// never more than 180° apart. A leg from Los Angeles (-118°) to Tokyo (140°)
/// then crosses the Pacific instead of Europe. The whole path is then shifted
/// so its middle lies within -180° to 180°, which keeps the camera on the
/// usual world.
List<Coordinates> routePath(TripRoute route) {
  final path = <Coordinates>[];
  double? previousLongitude;
  for (final leg in route.legs) {
    for (final point in [leg.fromCoordinates, leg.toCoordinates]) {
      var longitude = point.longitude;
      if (previousLongitude != null) {
        while (longitude - previousLongitude > 180) {
          longitude -= 360;
        }
        while (longitude - previousLongitude < -180) {
          longitude += 360;
        }
      }
      path.add(Coordinates(latitude: point.latitude, longitude: longitude));
      previousLongitude = longitude;
    }
  }
  if (path.isEmpty) return path;

  final longitudes = [for (final point in path) point.longitude];
  final middle = (longitudes.reduce(min) + longitudes.reduce(max)) / 2;
  final shift = 360 * (middle / 360).round();
  if (shift == 0) return path;
  return [
    for (final point in path)
      Coordinates(latitude: point.latitude, longitude: point.longitude - shift),
  ];
}
