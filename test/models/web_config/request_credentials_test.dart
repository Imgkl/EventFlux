import 'package:eventflux/src/models/web_config/request_credentials.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:test/test.dart';

void main() {
  group('WebConfigRequestCredentials.toRequestCredentials', () {
    test('sameOrigin converts to RequestCredentials.sameOrigin', () {
      expect(
        WebConfigRequestCredentials.sameOrigin.toRequestCredentials(),
        RequestCredentials.sameOrigin,
      );
    });

    test('omit converts to RequestCredentials.omit', () {
      expect(
        WebConfigRequestCredentials.omit.toRequestCredentials(),
        RequestCredentials.omit,
      );
    });

    test('cors converts to RequestCredentials.cors', () {
      expect(
        WebConfigRequestCredentials.cors.toRequestCredentials(),
        RequestCredentials.cors,
      );
    });
  });
}
