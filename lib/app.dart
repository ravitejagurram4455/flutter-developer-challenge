import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/trip_planner/domain/dijkstra_route_finder.dart';
import 'features/trip_planner/domain/route_finder.dart';
import 'features/trip_planner/domain/trip_repository.dart';
import 'features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import 'features/trip_planner/presentation/trip_planner_screen.dart';
import 'features/trip_planner/presentation/widgets/route_map.dart';

class TripPlannerApp extends StatelessWidget {
  const TripPlannerApp({super.key, required this.repository});

  final TripRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TripRepository>.value(value: repository),
        RepositoryProvider<RouteFinder>(
          create: (_) => const DijkstraRouteFinder(),
        ),
      ],
      child: BlocProvider(
        create: (context) => TripPlannerCubit(
          context.read<TripRepository>(),
          context.read<RouteFinder>(),
        )..load(),
        child: MaterialApp(
          title: 'Trip Planner',
          theme: AppTheme.light,
          scrollBehavior: const _SwipeWithMouseScrollBehavior(),
          home: TripPlannerScreen(
            mapBuilder: (route) => RouteMap(route: route),
          ),
        ),
      ),
    );
  }
}

/// Keeps the carousel swipeable on web and desktop, where a mouse drag does not
/// scroll by default.
class _SwipeWithMouseScrollBehavior extends MaterialScrollBehavior {
  const _SwipeWithMouseScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}
