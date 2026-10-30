import 'package:equatable/equatable.dart';

class City extends Equatable {
  const City({required this.name, this.imageUrl});

  final String name;

  /// Absolute image URL, or null when the API supplied none for this city.
  final String? imageUrl;

  @override
  List<Object?> get props => [name, imageUrl];
}
