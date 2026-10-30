import '../../domain/connection.dart';

class ConnectionDto {
  const ConnectionDto({
    required this.from,
    required this.to,
    required this.price,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
  });

  /// Throws [FormatException] if [json] is not a well-formed connection.
  factory ConnectionDto.fromJson(Object? json) {
    if (json
        case {
          'from': final String from,
          'to': final String to,
          'price': final num price,
          'coordinates': {
            'from': {
              'lat': final num fromLatitude,
              'long': final num fromLongitude,
            },
            'to': {'lat': final num toLatitude, 'long': final num toLongitude},
          },
        }
        when from.trim().isNotEmpty && to.trim().isNotEmpty) {
      return ConnectionDto(
        from: from,
        to: to,
        price: price,
        fromLatitude: fromLatitude,
        fromLongitude: fromLongitude,
        toLatitude: toLatitude,
        toLongitude: toLongitude,
      );
    }
    throw FormatException('Malformed connection: $json');
  }

  /// Throws [FormatException] if [json] is not a well-formed response. One bad
  /// record fails them all, as skipping it could hide the cheapest route.
  static List<ConnectionDto> listFromResponse(Object? json) {
    if (json case {'connections': final List<Object?> connections}) {
      return connections.map(ConnectionDto.fromJson).toList();
    }
    throw const FormatException('Expected an object with a connections list');
  }

  final String from;
  final String to;
  final num price;
  final num fromLatitude;
  final num fromLongitude;
  final num toLatitude;
  final num toLongitude;

  /// Throws [FormatException] if the values make no sense as a connection.
  Connection toDomain() {
    if (!price.isFinite || price < 0) {
      throw FormatException('Invalid price for $from -> $to: $price');
    }
    return Connection(
      from: from,
      to: to,
      priceInCents: (price * 100).round(),
      fromCoordinates: _coordinates(fromLatitude, fromLongitude),
      toCoordinates: _coordinates(toLatitude, toLongitude),
    );
  }

  Coordinates _coordinates(num latitude, num longitude) {
    if (latitude.abs() > 90 || longitude.abs() > 180) {
      throw FormatException(
        'Invalid coordinates for $from -> $to: $latitude, $longitude',
      );
    }
    return Coordinates(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }
}
