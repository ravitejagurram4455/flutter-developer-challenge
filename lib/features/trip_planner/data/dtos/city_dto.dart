import '../../domain/city.dart';

class CityDto {
  const CityDto({required this.name, required this.imageUrl});

  /// Throws [FormatException] if [json] is not a well-formed city.
  factory CityDto.fromJson(Object? json) {
    if (json case {'name': final String name, 'imageUrl': final String imageUrl}
        when name.trim().isNotEmpty) {
      return CityDto(name: name, imageUrl: imageUrl);
    }
    throw FormatException('Malformed city: $json');
  }

  /// Throws [FormatException] if [json] is not a well-formed response.
  static List<CityDto> listFromResponse(Object? json) {
    if (json case {'cities': final List<Object?> cities}) {
      return cities.map(CityDto.fromJson).toList();
    }
    throw const FormatException('Expected an object with a cities list');
  }

  final String name;
  final String imageUrl;

  City toDomain(Uri baseUrl) =>
      City(name: name, imageUrl: _resolveImageUrl(baseUrl));

  /// Relative paths resolve against [baseUrl]. So do absolute loopback URLs,
  /// because "localhost" means something else on an emulator or a device.
  String _resolveImageUrl(Uri baseUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return imageUrl;
    if (!uri.hasScheme) return baseUrl.resolveUri(uri).toString();
    if (!_loopbackHosts.contains(uri.host)) return imageUrl;
    return uri
        .replace(scheme: baseUrl.scheme, host: baseUrl.host, port: baseUrl.port)
        .toString();
  }

  static const _loopbackHosts = {'localhost', '127.0.0.1', '0.0.0.0'};
}
