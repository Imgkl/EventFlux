import 'package:eventflux/src/models/web_config/request_cache.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:test/test.dart';

void main() {
  group('WebConfigRequestCache.toRequestCache', () {
    test('byDefault converts to RequestCache.byDefault', () {
      expect(
        WebConfigRequestCache.byDefault.toRequestCache(),
        RequestCache.byDefault,
      );
    });

    test('noStore converts to RequestCache.noStore', () {
      expect(
        WebConfigRequestCache.noStore.toRequestCache(),
        RequestCache.noStore,
      );
    });

    test('reload converts to RequestCache.reload', () {
      expect(
        WebConfigRequestCache.reload.toRequestCache(),
        RequestCache.reload,
      );
    });

    test('noCache converts to RequestCache.noCache', () {
      expect(
        WebConfigRequestCache.noCache.toRequestCache(),
        RequestCache.noCache,
      );
    });

    test('forceCache converts to RequestCache.forceCache', () {
      expect(
        WebConfigRequestCache.forceCache.toRequestCache(),
        RequestCache.forceCache,
      );
    });

    test('onlyIfCached converts to RequestCache.onlyIfCached', () {
      expect(
        WebConfigRequestCache.onlyIfCached.toRequestCache(),
        RequestCache.onlyIfCached,
      );
    });
  });
}
