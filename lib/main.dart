import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'features/trip_planner/data/trip_remote_data_source.dart';
import 'features/trip_planner/data/trip_repository_impl.dart';

void main() {
  final apiClient = ApiClient(
    client: http.Client(),
    baseUrl: Uri.parse(AppConfig.apiBaseUrl),
  );
  final dataSource = TripRemoteDataSource(apiClient);
  runApp(TripPlannerApp(repository: TripRepositoryImpl(dataSource)));
}
