import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tui_challenge/core/error/failures.dart';
import 'package:flutter_tui_challenge/core/network/api_client.dart';
import 'package:flutter_tui_challenge/features/trip_planner/data/dtos/city_dto.dart';
import 'package:flutter_tui_challenge/features/trip_planner/data/dtos/connection_dto.dart';
import 'package:flutter_tui_challenge/features/trip_planner/data/trip_remote_data_source.dart';
import 'package:flutter_tui_challenge/features/trip_planner/data/trip_repository_impl.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/city.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/trip_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements TripRemoteDataSource {}

ConnectionDto _connection(String from, String to, {num price = 10}) =>
    ConnectionDto(
      from: from,
      to: to,
      price: price,
      fromLatitude: 0,
      fromLongitude: 0,
      toLatitude: 0,
      toLongitude: 0,
    );

void main() {
  late _MockDataSource dataSource;
  late TripRepositoryImpl repository;

  void stub({
    List<ConnectionDto> connections = const [],
    List<CityDto> cities = const [],
  }) {
    when(dataSource.fetchConnections).thenAnswer((_) async => connections);
    when(dataSource.fetchCities).thenAnswer((_) async => cities);
  }

  setUp(() {
    dataSource = _MockDataSource();
    repository = TripRepositoryImpl(dataSource);
    when(() => dataSource.baseUrl).thenReturn(Uri.parse('http://api.test'));
  });

  test('maps DTOs to domain entities', () async {
    stub(
      connections: [_connection('A', 'B', price: 1.5)],
      cities: const [
        CityDto(name: 'A', imageUrl: '/a.svg'),
        CityDto(name: 'B', imageUrl: '/b.svg'),
      ],
    );

    final data = await repository.loadTripData();

    expect(data.connections.single.priceInCents, 150);
    expect(data.cities, const [
      City(name: 'A', imageUrl: 'http://api.test/a.svg'),
      City(name: 'B', imageUrl: 'http://api.test/b.svg'),
    ]);
  });

  test(
    'adds connection cities missing from /cities, without an image',
    () async {
      stub(
        connections: [_connection('B', 'C')],
        cities: const [CityDto(name: 'A', imageUrl: '/a.svg')],
      );

      final data = await repository.loadTripData();

      expect(data.cities, const [
        City(name: 'A', imageUrl: 'http://api.test/a.svg'),
        City(name: 'B'),
        City(name: 'C'),
      ]);
    },
  );

  test('succeeds with empty lists', () async {
    stub();

    final data = await repository.loadTripData();

    expect(data.cities, isEmpty);
    expect(data.connections, isEmpty);
    expect(data.imagesUnavailable, isFalse);
  });

  test('requests /connections and /cities at the same time', () async {
    final connections = Completer<List<ConnectionDto>>();
    when(dataSource.fetchConnections).thenAnswer((_) => connections.future);
    when(dataSource.fetchCities).thenAnswer((_) async => const []);

    final load = repository.loadTripData();
    await Future<void>.delayed(Duration.zero);

    verify(dataSource.fetchCities).called(1);
    connections.complete([_connection('A', 'B')]);
    expect((await load).connections, hasLength(1));
  });

  group('when /cities fails, still loads the connections', () {
    final failures = <String, Exception>{
      'network error': const NetworkException('offline'),
      'server error': const ServerException(500),
      'invalid data': const FormatException('bad'),
    };

    for (final MapEntry(key: name, value: error) in failures.entries) {
      test(name, () async {
        stub(connections: [_connection('A', 'B')]);
        when(dataSource.fetchCities).thenThrow(error);

        final data = await repository.loadTripData();

        expect(
          data,
          TripData(
            cities: const [
              City(name: 'A'),
              City(name: 'B'),
            ],
            connections: data.connections,
            imagesUnavailable: true,
          ),
        );
        expect(data.connections, hasLength(1));
      });
    }
  });

  group('failures', () {
    Matcher throwsFailure<T extends Failure>() => throwsA(isA<T>());

    test('maps NetworkException to NetworkFailure', () {
      stub();
      when(dataSource.fetchConnections)
          .thenThrow(const NetworkException('offline'));

      expect(repository.loadTripData(), throwsFailure<NetworkFailure>());
    });

    test('maps ServerException to ServerFailure with its status', () {
      stub();
      when(dataSource.fetchConnections).thenThrow(const ServerException(500));

      expect(
        repository.loadTripData(),
        throwsA(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('maps FormatException to DataFailure', () {
      stub();
      when(dataSource.fetchConnections).thenThrow(const FormatException('bad'));

      expect(repository.loadTripData(), throwsFailure<DataFailure>());
    });

    test('reports a negative price as a DataFailure', () {
      stub(connections: [_connection('A', 'B', price: -1)]);

      expect(repository.loadTripData(), throwsFailure<DataFailure>());
    });
  });
}
