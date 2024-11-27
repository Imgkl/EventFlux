import 'package:eventflux/src/models/web_config/redirect_policy.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:test/test.dart';

void main() {
  group('WebConfigRedirectPolicy.toRedirectPolicy', () {
    test('alwaysFollow converts to RedirectPolicy.alwaysFollow', () {
      expect(
        WebConfigRedirectPolicy.alwaysFollow.toRedirectPolicy(),
        RedirectPolicy.alwaysFollow,
      );
    });

    test('probe converts to RedirectPolicy.probe', () {
      expect(
        WebConfigRedirectPolicy.probe.toRedirectPolicy(),
        RedirectPolicy.probe,
      );
    });

    test('probeHead converts to RedirectPolicy.probeHead', () {
      expect(
        WebConfigRedirectPolicy.probeHead.toRedirectPolicy(),
        RedirectPolicy.probeHead,
      );
    });
  });
}
