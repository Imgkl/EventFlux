import 'package:eventflux/src/models/web_config/web_config.dart';
import 'package:test/test.dart';

void main() {
  group('WebConfig', () {
    test('constructor has correct default values', () {
      expect(
        WebConfig(),
        WebConfig(
          mode: WebConfigRequestMode.noCors,
          credentials: WebConfigRequestCredentials.sameOrigin,
          cache: WebConfigRequestCache.byDefault,
          referrer: '',
          referrerPolicy:
              WebConfigRequestReferrerPolicy.strictOriginWhenCrossOrigin,
          redirectPolicy: WebConfigRedirectPolicy.alwaysFollow,
          streamRequests: false,
        ),
      );
    });

    group('copyWith', () {
      test('returns a copy of itself', () {
        final webConfig = WebConfig();
        final copy = webConfig.copyWith();
        expect(copy, webConfig);
      });

      test('returns a copy with the given fields replaced', () {
        final webConfig = WebConfig();
        final copy = webConfig.copyWith(
          mode: WebConfigRequestMode.sameOrigin,
          credentials: WebConfigRequestCredentials.cors,
        );
        expect(
          copy,
          WebConfig(
            mode: WebConfigRequestMode.sameOrigin,
            credentials: WebConfigRequestCredentials.cors,
          ),
        );
      });

      test('returns a copy with all fields replaced', () {
        final webConfig = WebConfig();
        final copy = webConfig.copyWith(
          mode: WebConfigRequestMode.sameOrigin,
          credentials: WebConfigRequestCredentials.cors,
          cache: WebConfigRequestCache.noCache,
          referrer: 'https://test.com',
          referrerPolicy: WebConfigRequestReferrerPolicy.noReferrer,
          redirectPolicy: WebConfigRedirectPolicy.probe,
          streamRequests: true,
        );
        expect(
          copy,
          WebConfig(
            mode: WebConfigRequestMode.sameOrigin,
            credentials: WebConfigRequestCredentials.cors,
            cache: WebConfigRequestCache.noCache,
            referrer: 'https://test.com',
            referrerPolicy: WebConfigRequestReferrerPolicy.noReferrer,
            redirectPolicy: WebConfigRedirectPolicy.probe,
            streamRequests: true,
          ),
        );
      });
    });
  });
}
