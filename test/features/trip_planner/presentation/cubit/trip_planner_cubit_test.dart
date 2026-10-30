import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tui_challenege/core/error/failures.dart';
import 'package:flutter_tui_challenege/features/trip_planner/domain/city.dart';
import 'package:flutter_tui_challenege/features/trip_planner/domain/connection.dart';
import 'package:flutter_tui_challenege/features/trip_planner/domain/route_finder.dart';
import 'package:flutter_tui_challenege/features/trip_planner/domain/trip_repository.dart';
import 'package:flutter_tui_challenege/features/trip_planner/domain/trip_route.dart';
import 'package:flutter_tui_challenege/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';
import 'package:flutter_tui_challenege/features/trip_planner/presentation/cubit/trip_planner_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements TripRepository {}

class _MockRouteFinder extends Mock implements RouteFinder {}

const _cities = [City(name: 'A'), City(name: 'B')];
const _connection = Connection(
  from: 'A',
  to: 'B',
  priceInCents: 100,
  fromCoordinates: Coordinates(latitude: 0, longitude: 0),
  toCoordinates: Coordinates(latitude: 1, longitude: 1),
);
const _connections = [_connection];
const _data = TripData(cities: _cities, connections: _connections);
const _route = TripRoute(_connections);
const _ready = TripPlannerReady(cities: _cities, connections: _connections);

void main() {
  late _MockRepository repository;
  late _MockRouteFinder routeFinder;

  TripPlannerCubit buildCubit() => TripPlannerCubit(repository, routeFinder);

  void stubRoute(TripRoute? route) {
    when(
      () => routeFinder.findCheapestRoute(
        connections: any(named: 'connections'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenReturn(route);
  }

  setUp(() {
    repository = _MockRepository();
    routeFinder = _MockRouteFinder();
  });

  test('starts loading', () {
    expect(buildCubit().state, const TripPlannerLoading());
  });

  group('load', () {
    blocTest<TripPlannerCubit, TripPlannerState>(
      'emits ready on success',
      setUp: () => when(repository.loadTripData).thenAnswer((_) async => _data),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [const TripPlannerLoading(), _ready],
    );

    blocTest<TripPlannerCubit, TripPlannerState>(
      'emits the failure when loading fails',
      setUp: () =>
          when(repository.loadTripData).thenThrow(const NetworkFailure()),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const TripPlannerLoading(),
        const TripPlannerLoadFailure(NetworkFailure()),
      ],
    );

    blocTest<TripPlannerCubit, TripPlannerState>(
      'recovers when a retry succeeds',
      setUp: () =>
          when(repository.loadTripData).thenThrow(const ServerFailure(500)),
      build: buildCubit,
      act: (cubit) async {
        await cubit.load();
        when(repository.loadTripData).thenAnswer((_) async => _data);
        await cubit.load();
      },
      expect: () => [
        const TripPlannerLoading(),
        const TripPlannerLoadFailure(ServerFailure(500)),
        const TripPlannerLoading(),
        _ready,
      ],
    );
  });

  group('selection', () {
    blocTest<TripPlannerCubit, TripPlannerState>(
      'carousel selection prefills the destination without searching',
      build: buildCubit,
      seed: () => _ready,
      act: (cubit) => cubit.selectDestination('B'),
      expect: () => [
        const TripPlannerReady(
          cities: _cities,
          connections: _connections,
          destination: 'B',
        ),
      ],
      verify: (_) => verifyZeroInteractions(routeFinder),
    );

    blocTest<TripPlannerCubit, TripPlannerState>(
      'emits the route once both cities are selected',
      setUp: () => stubRoute(_route),
      build: buildCubit,
      seed: () => _ready,
      act: (cubit) => cubit
        ..selectDeparture('A')
        ..selectDestination('B'),
      skip: 1,
      expect: () => [
        const TripPlannerReady(
          cities: _cities,
          connections: _connections,
          departure: 'A',
          destination: 'B',
          routeResult: RouteFound(_route),
        ),
      ],
      verify: (_) => verify(
        () => routeFinder.findCheapestRoute(
          connections: _connections,
          from: 'A',
          to: 'B',
        ),
      ).called(1),
    );

    blocTest<TripPlannerCubit, TripPlannerState>(
      'emits not found when no route exists',
      setUp: () => stubRoute(null),
      build: buildCubit,
      seed: () => _ready,
      act: (cubit) => cubit
        ..selectDeparture('B')
        ..selectDestination('A'),
      skip: 1,
      expect: () => [
        const TripPlannerReady(
          cities: _cities,
          connections: _connections,
          departure: 'B',
          destination: 'A',
          routeResult: RouteNotFound(),
        ),
      ],
    );

    blocTest<TripPlannerCubit, TripPlannerState>(
      'does not search for the same departure and destination',
      build: buildCubit,
      seed: () => const TripPlannerReady(
        cities: _cities,
        connections: _connections,
        departure: 'A',
      ),
      act: (cubit) => cubit.selectDestination('A'),
      expect: () => [
        isA<TripPlannerReady>()
            .having((s) => s.isSameCity, 'isSameCity', isTrue)
            .having(
              (s) => s.routeResult,
              'routeResult',
              const RouteNoneSelected(),
            ),
      ],
      verify: (_) => verifyZeroInteractions(routeFinder),
    );

    blocTest<TripPlannerCubit, TripPlannerState>(
      'clears the route when a city is cleared',
      build: buildCubit,
      seed: () => const TripPlannerReady(
        cities: _cities,
        connections: _connections,
        departure: 'A',
        destination: 'B',
        routeResult: RouteFound(_route),
      ),
      act: (cubit) => cubit.selectDestination(null),
      expect: () => [
        const TripPlannerReady(
          cities: _cities,
          connections: _connections,
          departure: 'A',
        ),
      ],
    );

    blocTest<TripPlannerCubit, TripPlannerState>(
      'ignores a selection while not ready',
      build: buildCubit,
      act: (cubit) => cubit.selectDeparture('A'),
      expect: () => const <TripPlannerState>[],
    );
  });
}
