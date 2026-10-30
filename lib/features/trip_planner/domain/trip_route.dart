import 'package:equatable/equatable.dart';

import 'connection.dart';

class TripRoute extends Equatable {
  const TripRoute(this.legs);

  /// The connections to take, in travel order.
  final List<Connection> legs;

  int get totalPriceInCents =>
      legs.fold(0, (total, leg) => total + leg.priceInCents);

  @override
  List<Object?> get props => [legs];
}
