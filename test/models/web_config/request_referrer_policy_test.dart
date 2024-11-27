import 'package:eventflux/models/web_config/request_referrer_policy.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:test/test.dart';

void main() {
  group('WebConfigRequestReferrerPolicy.toRequestReferrerPolicy', () {
    test('strictOriginWhenCrossOrigin converts correctly', () {
      expect(
        WebConfigRequestReferrerPolicy.strictOriginWhenCrossOrigin
            .toRequestReferrerPolicy(),
        RequestReferrerPolicy.strictOriginWhenCrossOrigin,
      );
    });

    test('noReferrer converts correctly', () {
      expect(
        WebConfigRequestReferrerPolicy.noReferrer.toRequestReferrerPolicy(),
        RequestReferrerPolicy.noReferrer,
      );
    });

    test('noReferrerWhenDowngrade converts correctly', () {
      expect(
        WebConfigRequestReferrerPolicy.noReferrerWhenDowngrade
            .toRequestReferrerPolicy(),
        RequestReferrerPolicy.noReferrerWhenDowngrade,
      );
    });

    test('sameOrigin converts correctly', () {
      expect(
        WebConfigRequestReferrerPolicy.sameOrigin.toRequestReferrerPolicy(),
        RequestReferrerPolicy.sameOrigin,
      );
    });

    test('origin converts correctly', () {
      expect(
        WebConfigRequestReferrerPolicy.origin.toRequestReferrerPolicy(),
        RequestReferrerPolicy.origin,
      );
    });

    test('strictOrigin converts correctly', () {
      expect(
        WebConfigRequestReferrerPolicy.strictOrigin.toRequestReferrerPolicy(),
        RequestReferrerPolicy.strictOrigin,
      );
    });

    test('originWhenCrossOrigin converts correctly', () {
      expect(
        WebConfigRequestReferrerPolicy.originWhenCrossOrigin
            .toRequestReferrerPolicy(),
        RequestReferrerPolicy.originWhenCrossOrigin,
      );
    });

    test('unsafeUrl converts correctly', () {
      expect(
        WebConfigRequestReferrerPolicy.unsafeUrl.toRequestReferrerPolicy(),
        RequestReferrerPolicy.unsafeUrl,
      );
    });
  });
}
