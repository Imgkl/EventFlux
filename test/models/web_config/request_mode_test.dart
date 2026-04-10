import 'package:eventflux/models/web_config/request_mode.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:test/test.dart';

void main() {
  group('WebConfigRequestMode.toRequestMode', () {
    test('sameOrigin converts to RequestMode.sameOrigin', () {
      expect(
        WebConfigRequestMode.sameOrigin.toRequestMode(),
        RequestMode.sameOrigin,
      );
    });

    test('noCors converts to RequestMode.noCors', () {
      expect(
        WebConfigRequestMode.noCors.toRequestMode(),
        RequestMode.noCors,
      );
    });

    test('cors converts to RequestMode.cors', () {
      expect(
        WebConfigRequestMode.cors.toRequestMode(),
        RequestMode.cors,
      );
    });

    test('navigate converts to RequestMode.navigate', () {
      expect(
        WebConfigRequestMode.navigate.toRequestMode(),
        RequestMode.navigate,
      );
    });

    test('webSocket converts to RequestMode.webSocket', () {
      expect(
        WebConfigRequestMode.webSocket.toRequestMode(),
        RequestMode.webSocket,
      );
    });
  });
}
