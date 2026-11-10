import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/connection.dart';
import '../../domain/trip_route.dart';
import 'route_path.dart';

/// Plots every leg of [route] on OpenStreetMap, fitted to the route.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.route});

  final TripRoute route;

  static LatLng _latLng(Coordinates coordinates) =>
      LatLng(coordinates.latitude, coordinates.longitude);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final points = [
      for (final leg in route.legs) ...[
        _latLng(leg.fromCoordinates),
        _latLng(leg.toCoordinates),
      ],
    ];
    return FlutterMap(
      // The initial fit only applies once, so each new route needs a new map.
      key: ValueKey(route),
      options: MapOptions(
        // flutter_map already draws each leg the short way. The camera fits a
        // path whose longitudes follow those legs, so a route that crosses the
        // antimeridian stays in view. LatLngBounds would clamp it to ±180°.
        initialCameraFit: CameraFit.coordinates(
          coordinates: [for (final point in routePath(route)) _latLng(point)],
          // Extra room at the bottom keeps markers clear of the attribution.
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 64),
          maxZoom: 10,
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: AppConfig.appId,
        ),
        PolylineLayer(
          polylines: [
            for (final leg in route.legs)
              Polyline(
                points: [
                  _latLng(leg.fromCoordinates),
                  _latLng(leg.toCoordinates),
                ],
                strokeWidth: 4,
                color: colorScheme.primary,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final point in points)
              Marker(
                point: point,
                width: 16,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }
}
