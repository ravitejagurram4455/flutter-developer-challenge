import '../../../core/network/api_client.dart';
import 'dtos/city_dto.dart';
import 'dtos/connection_dto.dart';

class TripRemoteDataSource {
  const TripRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// The base URL that relative image URLs resolve against.
  Uri get baseUrl => _apiClient.baseUrl;

  Future<List<ConnectionDto>> fetchConnections() async =>
      ConnectionDto.listFromResponse(await _apiClient.getJson('/connections'));

  Future<List<CityDto>> fetchCities() async =>
      CityDto.listFromResponse(await _apiClient.getJson('/cities'));
}
