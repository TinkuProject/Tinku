import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tinkuapp/services/api_http_client.dart';

void main() {
  group('ApiHttpClient', () {
    test('retries transient failures for GET requests', () async {
      var calls = 0;
      final client = ApiHttpClient(
        inner: MockClient((_) async {
          calls++;
          return http.Response(
              calls == 1 ? 'temporary' : 'ok', calls == 1 ? 503 : 200);
        }),
        retryDelay: Duration.zero,
      );

      final response = await client.get(Uri.parse('https://tinku.test/items'));

      expect(response.statusCode, 200);
      expect(response.body, 'ok');
      expect(calls, 2);
      client.close();
    });

    test('does not retry write requests', () async {
      var calls = 0;
      final client = ApiHttpClient(
        inner: MockClient((_) async {
          calls++;
          return http.Response('temporary', 503);
        }),
        retryDelay: Duration.zero,
      );

      final response = await client.post(Uri.parse('https://tinku.test/items'));

      expect(response.statusCode, 503);
      expect(calls, 1);
      client.close();
    });

    test('stops waiting when the request timeout expires', () async {
      final client = ApiHttpClient(
        inner: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return http.Response('late', 200);
        }),
        requestTimeout: const Duration(milliseconds: 10),
        maxReadRetries: 0,
      );

      await expectLater(
        client.get(Uri.parse('https://tinku.test/slow')),
        throwsA(isA<ApiTimeoutException>()),
      );
      client.close();
    });

    test('cancels an older request with the same latest-request key', () async {
      final firstStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      final client = ApiHttpClient(
        inner: MockClient((request) async {
          if (request.url.queryParameters['q'] == 'old') {
            firstStarted.complete();
            await releaseFirst.future;
          }
          return http.Response('ok', 200);
        }),
        maxReadRetries: 0,
      );
      final headers = {
        ApiHttpClient.latestRequestKeyHeader: 'marketplace-search',
      };

      final first = client.get(
        Uri.parse('https://tinku.test/items?q=old'),
        headers: headers,
      );
      await firstStarted.future;

      final second = client.get(
        Uri.parse('https://tinku.test/items?q=new'),
        headers: headers,
      );

      await expectLater(first, throwsA(isA<ApiRequestCancelledException>()));
      expect((await second).statusCode, 200);
      releaseFirst.complete();
      client.close();
    });

    test('does not send internal control headers to the API', () async {
      final client = ApiHttpClient(
        inner: MockClient((request) async {
          expect(
            request.headers.containsKey(ApiHttpClient.latestRequestKeyHeader),
            isFalse,
          );
          expect(
            request.headers.containsKey(ApiHttpClient.timeoutSecondsHeader),
            isFalse,
          );
          return http.Response('ok', 200);
        }),
      );

      await client.get(
        Uri.parse('https://tinku.test/items'),
        headers: {
          ApiHttpClient.latestRequestKeyHeader: 'items',
          ApiHttpClient.timeoutSecondsHeader: '30',
        },
      );
      client.close();
    });
  });
}
