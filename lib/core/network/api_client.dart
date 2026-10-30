import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class NetworkException implements Exception {
  const NetworkException(this.cause);

  final Object cause;

  @override
  String toString() => 'NetworkException: $cause';
}

class ServerException implements Exception {
  const ServerException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'ServerException: HTTP $statusCode';
}

class ApiClient {
  const ApiClient({
    required this._client,
    required this.baseUrl,
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client _client;
  final Uri baseUrl;
  final Duration timeout;

  /// Returns the decoded JSON body of a GET to [path].
  ///
  /// Throws [NetworkException] if the request fails or times out,
  /// [ServerException] on a non-2xx status and [FormatException] if the body is
  /// not JSON.
  Future<Object?> getJson(String path) async {
    final http.Response response;
    try {
      response = await _client.get(baseUrl.resolve(path)).timeout(timeout);
    } on http.ClientException catch (error) {
      throw NetworkException(error);
    } on TimeoutException catch (error) {
      throw NetworkException(error);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerException(response.statusCode);
    }
    // JSON is UTF-8, whatever charset the response headers leave out.
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
