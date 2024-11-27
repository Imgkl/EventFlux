@TestOn('browser')
import 'dart:async';

import 'package:eventflux/src/client.dart';
import 'package:eventflux/src/enum.dart';
import 'package:eventflux/src/models/web_config/web_config.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:test/test.dart';

/// Run this with `flutter test --platform chrome test/browser/eventflux_test_browser.dart`
void main() {
  late EventFlux eventFlux;

  setUp(() {
    eventFlux = EventFlux.spawn();
  });

  for (final connectionType in [
    EventFluxConnectionType.get,
    EventFluxConnectionType.post,
  ]) {
    test(
      'uses FetchClient in browser environment with correct config for $connectionType',
      () {
        final events = <String>[];
        final completer = Completer<void>();
        const testUrl = 'https://localhost:4567';

        fakeAsync((async) {
          eventFlux.connect(
            connectionType,
            testUrl,
            webConfig: WebConfig(
              mode: WebConfigRequestMode.sameOrigin,
              credentials: WebConfigRequestCredentials.cors,
              cache: WebConfigRequestCache.noCache,
              referrer: 'https://localhost:4567',
              referrerPolicy: WebConfigRequestReferrerPolicy.noReferrer,
              redirectPolicy: WebConfigRedirectPolicy.probe,
              streamRequests: true,
            ),
            onSuccessCallback: (response) {
              response?.stream?.listen(
                (event) {
                  events.add(event.data);
                  if (events.length >= 3) {
                    completer.complete();
                  }
                },
                onError: (error) => completer.completeError(error),
              );
            },
            onError: (error) => completer.completeError(error),
          );
        });

        expect(
          eventFlux.client,
          isA<FetchClient>()
              .having(
                (c) => c.mode,
                'mode',
                RequestMode.sameOrigin,
              )
              .having(
                (c) => c.credentials,
                'credentials',
                RequestCredentials.cors,
              )
              .having(
                (c) => c.cache,
                'cache',
                RequestCache.noCache,
              )
              .having(
                (c) => c.referrer,
                'referrer',
                'https://localhost:4567',
              )
              .having(
                (c) => c.referrerPolicy,
                'referrerPolicy',
                RequestReferrerPolicy.noReferrer,
              )
              .having(
                (c) => c.redirectPolicy,
                'redirectPolicy',
                RedirectPolicy.probe,
              )
              .having(
                (c) => c.streamRequests,
                'streamRequests',
                true,
              ),
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  }

  test('throws Assertion error if webConfig is not provided', () {
    expect(
      () => fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          'https://localhost:4567',
          onSuccessCallback: (_) {},
          onError: (_) {},
        );
      }),
      throwsA(isA<AssertionError>()),
    );
  });
}
