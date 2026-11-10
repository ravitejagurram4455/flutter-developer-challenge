import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tui_challenge/features/trip_planner/data/dtos/connection_dto.dart';
import 'package:flutter_tui_challenge/features/trip_planner/domain/connection.dart';

Map<String, Object?> _validJson() => {
  'from': 'A',
  'to': 'B',
  'price': 120,
  'coordinates': {
    'from': {'lat': 10.5, 'long': -20.25},
    'to': {'lat': -30, 'long': 40},
  },
};

void main() {
  group('fromJson', () {
    test('parses a valid connection into a domain entity', () {
      expect(
        ConnectionDto.fromJson(_validJson()).toDomain(),
        const Connection(
          from: 'A',
          to: 'B',
          priceInCents: 12000,
          fromCoordinates: Coordinates(latitude: 10.5, longitude: -20.25),
          toCoordinates: Coordinates(latitude: -30, longitude: 40),
        ),
      );
    });

    test('ignores unknown fields', () {
      final json = _validJson()..['airline'] = 'X';

      expect(ConnectionDto.fromJson(json).from, 'A');
    });

    for (final field in ['from', 'to', 'price', 'coordinates']) {
      test('rejects a missing $field', () {
        final json = _validJson()..remove(field);

        expect(() => ConnectionDto.fromJson(json), throwsFormatException);
      });
    }

    for (final (field, value) in [
      ('from', 1),
      ('to', null),
      ('from', '  '),
      ('price', '120'),
      ('price', true),
      ('coordinates', 'nowhere'),
    ]) {
      test('rejects $field set to ${value.runtimeType} "$value"', () {
        final json = _validJson()..[field] = value;

        expect(() => ConnectionDto.fromJson(json), throwsFormatException);
      });
    }

    test('rejects missing or wrong-typed nested coordinates', () {
      final missingEnd = _validJson()
        ..['coordinates'] = {
          'from': {'lat': 1, 'long': 2},
        };
      final stringLatitude = _validJson()
        ..['coordinates'] = {
          'from': {'lat': '1', 'long': 2},
          'to': {'lat': 1, 'long': 2},
        };

      expect(() => ConnectionDto.fromJson(missingEnd), throwsFormatException);
      expect(
        () => ConnectionDto.fromJson(stringLatitude),
        throwsFormatException,
      );
    });

    test('rejects a record that is not an object', () {
      expect(() => ConnectionDto.fromJson('A to B'), throwsFormatException);
    });
  });

  group('listFromResponse', () {
    test('parses every connection', () {
      final response = {
        'connections': [_validJson(), _validJson()],
      };

      expect(ConnectionDto.listFromResponse(response), hasLength(2));
    });

    test('accepts an empty list', () {
      expect(ConnectionDto.listFromResponse({'connections': []}), isEmpty);
    });

    test('rejects a response of the wrong shape', () {
      for (final response in [
        null,
        [],
        {},
        {'connections': 'none'},
      ]) {
        expect(
          () => ConnectionDto.listFromResponse(response),
          throwsFormatException,
          reason: '$response',
        );
      }
    });

    test('rejects the whole list when one record is malformed', () {
      final response = {
        'connections': [_validJson(), <String, Object?>{}],
      };

      expect(
        () => ConnectionDto.listFromResponse(response),
        throwsFormatException,
      );
    });
  });

  group('toDomain', () {
    Connection convert(void Function(Map<String, Object?> json) edit) {
      final json = _validJson();
      edit(json);
      return ConnectionDto.fromJson(json).toDomain();
    }

    test('converts decimal prices to exact cents', () {
      expect(convert((j) => j['price'] = 19.99).priceInCents, 1999);
      expect(convert((j) => j['price'] = 0.07).priceInCents, 7);
      expect(convert((j) => j['price'] = 1.1).priceInCents, 110);
    });

    test('accepts a zero price', () {
      expect(convert((j) => j['price'] = 0).priceInCents, 0);
    });

    test('rejects a negative price, however small', () {
      expect(() => convert((j) => j['price'] = -1), throwsFormatException);
      expect(() => convert((j) => j['price'] = -0.001), throwsFormatException);
    });

    test('rejects a price that is not finite', () {
      expect(
        () => convert((j) => j['price'] = double.infinity),
        throwsFormatException,
      );
    });

    test('rejects coordinates outside the valid range', () {
      for (final end in [
        {'lat': 90.5, 'long': 0},
        {'lat': -90.5, 'long': 0},
        {'lat': 0, 'long': 180.5},
        {'lat': 0, 'long': -180.5},
      ]) {
        expect(
          () => convert(
            (j) => j['coordinates'] = {
              'from': end,
              'to': {'lat': 0, 'long': 0},
            },
          ),
          throwsFormatException,
          reason: '$end',
        );
      }
    });
  });
}
