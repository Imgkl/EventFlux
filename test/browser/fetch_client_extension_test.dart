@TestOn('browser')
import 'package:eventflux/src/extensions/fetch_client_extension.dart';
import 'package:eventflux/src/models/web_config/web_config.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:test/test.dart';

/// Run this with `flutter test test/browser/fetch_client_extensions_test.dart`
void main() {
  group('FetchClientExtension', () {
    test('fromWebConfig creates FetchClient with correct parameters', () {
      final webConfig = WebConfig(
        mode: WebConfigRequestMode.sameOrigin,
        credentials: WebConfigRequestCredentials.cors,
        cache: WebConfigRequestCache.noCache,
        referrer: 'https://test.com',
        referrerPolicy: WebConfigRequestReferrerPolicy.noReferrer,
        redirectPolicy: WebConfigRedirectPolicy.probe,
        streamRequests: true,
      );

      final result = FetchClientExtension.fromWebConfig(webConfig);

      expect(
        result,
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
              'https://test.com',
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
    });

    test('fromWebConfig creates FetchClient with default WebConfig values', () {
      final webConfig = WebConfig();

      final result = FetchClientExtension.fromWebConfig(webConfig);

      expect(
        result,
        isA<FetchClient>()
            .having(
              (c) => c.mode,
              'mode',
              RequestMode.noCors,
            )
            .having(
              (c) => c.credentials,
              'credentials',
              RequestCredentials.sameOrigin,
            )
            .having(
              (c) => c.cache,
              'cache',
              RequestCache.byDefault,
            )
            .having(
              (c) => c.referrer,
              'referrer',
              '',
            )
            .having(
              (c) => c.referrerPolicy,
              'referrerPolicy',
              RequestReferrerPolicy.strictOriginWhenCrossOrigin,
            )
            .having(
              (c) => c.redirectPolicy,
              'redirectPolicy',
              RedirectPolicy.alwaysFollow,
            )
            .having(
              (c) => c.streamRequests,
              'streamRequests',
              false,
            ),
      );
    });
  });
}
