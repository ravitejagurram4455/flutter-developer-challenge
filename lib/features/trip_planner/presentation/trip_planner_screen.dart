import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/trip_route.dart';
import 'cubit/trip_planner_cubit.dart';
import 'cubit/trip_planner_state.dart';
import 'widgets/city_autocomplete_field.dart';
import 'widgets/destination_carousel.dart';
import 'widgets/route_results.dart';
import 'widgets/status_views.dart';

class TripPlannerScreen extends StatelessWidget {
  const TripPlannerScreen({super.key, required this.mapBuilder});

  /// Builds the route map. Replaceable so tests never need network tiles.
  final Widget Function(TripRoute route) mapBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Planner')),
      body: BlocBuilder<TripPlannerCubit, TripPlannerState>(
        builder: (context, state) => switch (state) {
          TripPlannerLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          TripPlannerLoadFailure(:final failure) => StatusView(
            icon: Icons.cloud_off,
            title: 'Could not load destinations',
            message: failure.message,
            onRetry: context.read<TripPlannerCubit>().load,
          ),
          TripPlannerReady(cities: []) => StatusView(
            icon: Icons.travel_explore,
            title: 'No destinations available',
            onRetry: context.read<TripPlannerCubit>().load,
          ),
          final TripPlannerReady ready => _ReadyView(
            state: ready,
            mapBuilder: mapBuilder,
          ),
        },
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.state, required this.mapBuilder});

  final TripPlannerReady state;
  final Widget Function(TripRoute route) mapBuilder;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripPlannerCubit>();
    final cityNames = [for (final city in state.cities) city.name];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.imagesUnavailable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: NoticeBanner(
                    icon: Icons.image_not_supported_outlined,
                    message:
                        'Destination images could not be loaded. '
                        'Routes still work.',
                    onRetry: cubit.load,
                  ),
                ),
              DestinationCarousel(
                cities: state.cities,
                selected: state.destination,
                onSelected: cubit.selectDestination,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    CityAutocompleteField(
                      label: 'Departure',
                      icon: Icons.flight_takeoff,
                      cityNames: cityNames,
                      selected: state.departure,
                      onChanged: cubit.selectDeparture,
                    ),
                    CityAutocompleteField(
                      label: 'Destination',
                      icon: Icons.flight_land,
                      cityNames: cityNames,
                      selected: state.destination,
                      onChanged: cubit.selectDestination,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: KeyedSubtree(
                        key: ValueKey(state.routeResult),
                        child: _buildResult(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return switch (state.routeResult) {
      RouteNoneSelected() when state.isSameCity => const StatusView(
        icon: Icons.sync_alt,
        title: 'Departure and destination are the same',
        message: 'Choose two different cities to see a route.',
      ),
      RouteNoneSelected() => const StatusView(
        icon: Icons.flight,
        title: 'Where to next?',
        message:
            'Choose a departure and a destination to see the cheapest route.',
      ),
      RouteNotFound() => StatusView(
        icon: Icons.wrong_location_outlined,
        title: 'No route found',
        message:
            'There is no way to fly from ${state.departure} to '
            '${state.destination}.',
      ),
      RouteFound(:final route) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          RouteResults(route: route),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(height: 300, child: mapBuilder(route)),
          ),
        ],
      ),
    };
  }
}
