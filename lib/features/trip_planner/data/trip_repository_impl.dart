import '../../../core/error/failures.dart';
import '../../../core/network/api_client.dart';
import '../domain/city.dart';
import '../domain/trip_repository.dart';
import 'dtos/city_dto.dart';
import 'trip_remote_data_source.dart';

class TripRepositoryImpl implements TripRepository {
  const TripRepositoryImpl(this._dataSource);

  final TripRemoteDataSource _dataSource;

  @override
  Future<TripData> loadTripData() async {
    // Both requests run at once. Only /connections is required, because routes
    // need nothing else: without /cities the app still works, minus images.
    final citiesRequest = _fetchCitiesOrNull();
    try {
      final connections = (await _dataSource.fetchConnections())
          .map((dto) => dto.toDomain())
          .toList();
      final cityDtos = await citiesRequest;

      // Every city in the connections must be selectable, image or not.
      final citiesByName = {
        for (final connection in connections) ...{
          connection.from: City(name: connection.from),
          connection.to: City(name: connection.to),
        },
        for (final dto in cityDtos ?? const <CityDto>[])
          dto.name: dto.toDomain(_dataSource.baseUrl),
      };
      final cities = citiesByName.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return TripData(
        cities: cities,
        connections: connections,
        imagesUnavailable: cityDtos == null,
      );
    } on NetworkException {
      throw const NetworkFailure();
    } on ServerException catch (error) {
      throw ServerFailure(error.statusCode);
    } on FormatException {
      throw const DataFailure();
    }
  }

  /// The cities from /cities, or null if they could not be loaded.
  Future<List<CityDto>?> _fetchCitiesOrNull() async {
    try {
      return await _dataSource.fetchCities();
    } on NetworkException {
      return null;
    } on ServerException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
