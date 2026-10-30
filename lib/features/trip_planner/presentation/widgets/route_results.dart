import 'package:flutter/material.dart';

import '../../domain/trip_route.dart';
import '../price_format.dart';

class RouteResults extends StatelessWidget {
  const RouteResults({super.key, required this.route});

  final TripRoute route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legCount = route.legs.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total price', style: theme.textTheme.labelLarge),
                  Text(
                    formatPrice(route.totalPriceInCents),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(legCount == 1 ? 'Direct, 1 leg' : '$legCount legs'),
                ],
              ),
            ),
            const Divider(),
            for (final (index, leg) in route.legs.indexed)
              ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text('${leg.from} → ${leg.to}'),
                trailing: Text(
                  formatPrice(leg.priceInCents),
                  style: theme.textTheme.titleMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
