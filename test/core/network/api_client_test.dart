import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tui_challenege/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  ApiClient clientFor(MockClientHandler handler) => ApiClient(
    client: MockClient(handler),
    baseUrl: Uri.parse('http://api.test:1234'),
    timeout: const Duration(milliseconds: 20),
  );

  test('requests the path on the base URL and decodes the body', () async {
    late Uri requested;
    final client = clientFor((request) async {
      requested = request.url;
      return http.Response('{"a":1}', 200);
    });

    expect(await client.getJson('/things'), {'a': 1});
    expect(requested.toString(), 'http://api.test:1234/things');
  });

  test('decodes UTF-8 even without a charset header', () async {
    final client = clientFor(
      (_) async => http.Response.bytes(
        utf8.encode('{"name":"São Paulo"}'),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    expect(await client.getJson('/'), {'name': 'São Paulo'});
  });

  test('throws ServerException on a non-2xx status', () {
    final client = clientFor((_) async => http.Response('nope', 503));

    expect(
      client.getJson('/'),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'statusCode', 503),
      ),
    );
  });

  test('throws NetworkException when the request fails', () {
    final client = clientFor((_) async => throw http.ClientException('down'));

    expect(client.getJson('/'), throwsA(isA<NetworkException>()));
  });

  test('throws NetworkException on a timeout', () {
    final never = Completer<http.Response>();
    final client = clientFor((_) => never.future);

    expect(client.getJson('/'), throwsA(isA<NetworkException>()));
  });

  test('throws FormatException when the body is not JSON', () {
    final client = clientFor((_) async => http.Response('<html>', 200));

    expect(client.getJson('/'), throwsFormatException);
  });
}
