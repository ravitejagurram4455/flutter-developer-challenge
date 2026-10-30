import 'package:equatable/equatable.dart';

class Coordinates extends Equatable {
  const Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// A directed flight: [from] -> [to] says nothing about [to] -> [from].
class Connection extends Equatable {
  const Connection({
    required this.from,
    required this.to,
    required this.priceInCents,
    required this.fromCoordinates,
    required this.toCoordinates,
  });

  final String from;
  final String to;

  /// Whole cents, so that totals never accumulate floating-point errors.
  final int priceInCents;

  final Coordinates fromCoordinates;
  final Coordinates toCoordinates;

  @override
  List<Object?> get props => [
    from,
    to,
    priceInCents,
    fromCoordinates,
    toCoordinates,
  ];
}
