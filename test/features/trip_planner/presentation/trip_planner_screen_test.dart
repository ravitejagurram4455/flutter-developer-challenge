import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tui_challenge/core/error/failures.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/city.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/connection.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/dijkstra_route_finder.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/trip_repository.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/trip_route.dart';
import 'package:flutter_tui_challenge/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import 'package:flutter_tui_challenge/features/trip_planner/presentation/trip_planner_screen.dart';

import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements TripRepository {}

Connection _leg(String from, String to, int priceInCents) => Connection(
  from: from,
  to: to,
  priceInCents: priceInCents,
  fromCoordinates: const Coordinates(latitude: 0, longitude: 0),
  toCoordinates: const Coordinates(latitude: 1, longitude: 1),
);

final _data = TripData(
  cities: const [
    City(name: 'Alpha'),
    City(name: 'Beta'),
    City(name: 'Gamma'),
  ],
  connections: [_leg('Alpha', 'Beta', 1050), _leg('Beta', 'Gamma', 2000)],
);

void main() {
  late _MockRepository repository;
  late List<TripRoute> mappedRoutes;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) =>
            TripPlannerCubit(repository, const DijkstraRouteFinder())..load(),
        child: MaterialApp(
          home: TripPlannerScreen(
            mapBuilder: (route) {
              mappedRoutes.add(route);
              return const Text('map placeholder');
            },
          ),
        ),
      ),
    );
  }

  Future<void> enterCity(WidgetTester tester, String label, String city) async {
    await tester.enterText(find.widgetWithText(TextField, label), city);
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _MockRepository();
    mappedRoutes = [];
  });

  testWidgets('shows a spinner while loading', (tester) async {
    final pending = Completer<TripData>();
    when(repository.loadTripData).thenAnswer((_) => pending.future);

    await pumpScreen(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error, and retrying loads the data', (tester) async {
    when(repository.loadTripData).thenThrow(const NetworkFailure());

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Could not load destinations'), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    when(repository.loadTripData).thenAnswer((_) async => _data);
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load destinations'), findsNothing);
    expect(find.widgetWithText(TextField, 'Departure'), findsOneWidget);
  });

  testWidgets('finds routes without images, and retrying keeps the cities', (
    tester,
  ) async {
    when(repository.loadTripData).thenAnswer(
      (_) async => TripData(
        cities: _data.cities,
        connections: _data.connections,
        imagesUnavailable: true,
      ),
    );

    await pumpScreen(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('images could not be loaded'), findsOneWidget);

    await enterCity(tester, 'Departure', 'Alpha');
    await enterCity(tester, 'Destination', 'Gamma');
    expect(find.text('30.50'), findsOneWidget);

    when(repository.loadTripData).thenAnswer((_) async => _data);
    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.textContaining('images could not be loaded'), findsNothing);
    String fieldText(String label) => tester
        .widget<TextField>(find.widgetWithText(TextField, label))
        .controller!
        .text;
    expect(fieldText('Departure'), 'Alpha');
    expect(fieldText('Destination'), 'Gamma');
    expect(find.text('30.50'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no cities', (tester) async {
    when(repository.loadTripData)
        .thenAnswer((_) async => const TripData(cities: [], connections: []));

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('No destinations available'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });

  group('when ready', () {
    setUp(() {
      when(repository.loadTripData).thenAnswer((_) async => _data);
    });

    testWidgets('prompts for cities first', (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Where to next?'), findsOneWidget);
      expect(mappedRoutes, isEmpty);
    });

    testWidgets('shows the ordered legs, total and map of a route', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await enterCity(tester, 'Departure', 'Alpha');
      await enterCity(tester, 'Destination', 'Gamma');

      expect(find.text('30.50'), findsOneWidget);
      expect(find.text('2 legs'), findsOneWidget);
      expect(find.text('10.50'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      final firstLeg = tester.getTopLeft(find.text('Alpha → Beta'));
      final secondLeg = tester.getTopLeft(find.text('Beta → Gamma'));
      expect(firstLeg.dy, lessThan(secondLeg.dy));
      expect(find.text('map placeholder'), findsOneWidget);
      expect(mappedRoutes.last.legs, hasLength(2));
    });

    testWidgets('says so when no route exists', (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await enterCity(tester, 'Departure', 'Gamma');
      await enterCity(tester, 'Destination', 'Alpha');

      expect(find.text('No route found'), findsOneWidget);
      expect(find.text('map placeholder'), findsNothing);
    });

    testWidgets('explains instead of searching for the same city', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await enterCity(tester, 'Departure', 'Alpha');
      await enterCity(tester, 'Destination', 'alpha');

      expect(
        find.text('Departure and destination are the same'),
        findsOneWidget,
      );
      expect(find.text('Total price'), findsNothing);
    });

    testWidgets('tapping a carousel card prefills the destination', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Card, 'Alpha'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Destination'),
      );
      expect(field.controller?.text, 'Alpha');
    });

    testWidgets('suggests cities that match the typed text', (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextField, 'Departure'));
      await enterCity(tester, 'Departure', 'et');

      expect(find.widgetWithText(ListTile, 'Beta'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Alpha'), findsNothing);

      await tester.tap(find.widgetWithText(ListTile, 'Beta'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Departure'),
      );
      expect(field.controller?.text, 'Beta');
    });

    testWidgets('keeps up with several changes to both cities', (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await enterCity(tester, 'Departure', 'Alpha');
      await enterCity(tester, 'Destination', 'Gamma');
      expect(find.text('2 legs'), findsOneWidget);

      await enterCity(tester, 'Departure', 'Gamma');
      expect(
        find.text('Departure and destination are the same'),
        findsOneWidget,
      );

      await enterCity(tester, 'Departure', 'Alpha');
      await enterCity(tester, 'Destination', 'Beta');
      expect(find.text('Direct, 1 leg'), findsOneWidget);
    });

    testWidgets('editing a city away clears the route', (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await enterCity(tester, 'Departure', 'Alpha');
      await enterCity(tester, 'Destination', 'Beta');
      expect(find.text('Total price'), findsOneWidget);

      await enterCity(tester, 'Destination', 'Bet');

      expect(find.text('Total price'), findsNothing);
      expect(find.text('Where to next?'), findsOneWidget);
    });
  });
}
