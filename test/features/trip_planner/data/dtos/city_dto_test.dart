import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tui_challenge/features/trip_planner/data/dtos/city_dto.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/city.dart';

void main() {
  final baseUrl = Uri.parse('http://api.test:1234');

  String? imageUrlFor(String raw, {Uri? base}) =>
      CityDto(name: 'A', imageUrl: raw).toDomain(base ?? baseUrl).imageUrl;

  group('fromJson', () {
    test('parses a valid city', () {
      final dto = CityDto.fromJson({'name': 'A', 'imageUrl': '/a.svg'});

      expect(
        dto.toDomain(baseUrl),
        const City(name: 'A', imageUrl: 'http://api.test:1234/a.svg'),
      );
    });

    for (final json in [
      {'imageUrl': '/a.svg'},
      {'name': 'A'},
      {'name': 1, 'imageUrl': '/a.svg'},
      {'name': '', 'imageUrl': '/a.svg'},
      {'name': 'A', 'imageUrl': 2},
      'A',
    ]) {
      test('rejects $json', () {
        expect(() => CityDto.fromJson(json), throwsFormatException);
      });
    }
  });

  group('listFromResponse', () {
    test('parses every city', () {
      final response = {
        'cities': [
          {'name': 'A', 'imageUrl': '/a.svg'},
        ],
      };

      expect(CityDto.listFromResponse(response), hasLength(1));
    });

    test('accepts an empty list', () {
      expect(CityDto.listFromResponse({'cities': []}), isEmpty);
    });

    test('rejects a response of the wrong shape', () {
      for (final response in [
        null,
        [],
        {'cities': 1},
      ]) {
        expect(
          () => CityDto.listFromResponse(response),
          throwsFormatException,
          reason: '$response',
        );
      }
    });
  });

  group('image URL resolution', () {
    test('resolves a relative path against the base URL', () {
      expect(imageUrlFor('/assets/a.svg'), 'http://api.test:1234/assets/a.svg');
      expect(imageUrlFor('assets/a.svg'), 'http://api.test:1234/assets/a.svg');
    });

    test('points absolute loopback URLs at the configured host', () {
      for (final host in ['localhost', '127.0.0.1', '0.0.0.0']) {
        expect(
          imageUrlFor('http://$host:8000/assets/a.svg'),
          'http://api.test:1234/assets/a.svg',
          reason: host,
        );
      }
    });

    test('supports the Android emulator host', () {
      expect(
        imageUrlFor(
          'http://localhost:8000/a.svg',
          base: Uri.parse('http://10.0.2.2:8000'),
        ),
        'http://10.0.2.2:8000/a.svg',
      );
    });

    test('leaves other absolute URLs alone', () {
      expect(imageUrlFor('https://cdn.test/a.svg'), 'https://cdn.test/a.svg');
    });

    test('keeps an unparseable URL so that the UI shows its fallback', () {
      expect(imageUrlFor('http://[bad'), 'http://[bad');
    });
  });
}
