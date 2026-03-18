import 'package:eventflux/enum.dart';
import 'package:eventflux/models/reconnect.dart';
import 'package:eventflux/models/web_config/web_config.dart';
import 'package:eventflux/src/connection_config.dart';
import 'package:test/test.dart';

void main() {
  group('ConnectionConfig', () {
    test('constructs with required parameters only', () {
      final config = ConnectionConfig(
        type: EventFluxConnectionType.get,
        url: 'http://example.com/sse',
        onSuccessCallback: (_) {},
      );

      expect(config.type, EventFluxConnectionType.get);
      expect(config.url, 'http://example.com/sse');
      expect(config.header, {'Accept': 'text/event-stream', 'Cache-Control': 'no-store'});
      expect(config.autoReconnect, false);
      expect(config.reconnectConfig, isNull);
      expect(config.onError, isNull);
      expect(config.onConnectionClose, isNull);
      expect(config.httpClient, isNull);
      expect(config.body, isNull);
      expect(config.tag, isNull);
      expect(config.logReceivedData, false);
      expect(config.files, isNull);
      expect(config.multipartRequest, false);
      expect(config.webConfig, isNull);
      expect(config.interceptors, isNull);
      expect(config.abortTrigger, isNull);
    });

    test('constructs with all parameters', () {
      final reconnectConfig = ReconnectConfig(
        mode: ReconnectMode.linear,
        interval: const Duration(seconds: 5),
        maxAttempts: 3,
      );
      final webConfig = WebConfig();

      final config = ConnectionConfig(
        type: EventFluxConnectionType.post,
        url: 'http://example.com/sse',
        onSuccessCallback: (_) {},
        header: {'X-Custom': 'value'},
        autoReconnect: true,
        reconnectConfig: reconnectConfig,
        onError: (_) {},
        onConnectionClose: () {},
        body: {'key': 'value'},
        tag: 'test-tag',
        logReceivedData: true,
        multipartRequest: true,
        webConfig: webConfig,
      );

      expect(config.type, EventFluxConnectionType.post);
      expect(config.header, {'X-Custom': 'value'});
      expect(config.autoReconnect, true);
      expect(config.reconnectConfig, reconnectConfig);
      expect(config.body, {'key': 'value'});
      expect(config.tag, 'test-tag');
      expect(config.logReceivedData, true);
      expect(config.multipartRequest, true);
      expect(config.webConfig, webConfig);
    });

    test('copyWithHeader returns new config with updated header', () {
      final original = ConnectionConfig(
        type: EventFluxConnectionType.get,
        url: 'http://example.com/sse',
        onSuccessCallback: (_) {},
        header: {'Accept': 'text/event-stream'},
        tag: 'my-tag',
        autoReconnect: true,
      );

      final newHeaders = {'Authorization': 'Bearer token'};
      final copied = original.copyWithHeader(newHeaders);

      expect(copied.header, newHeaders);
      // All other fields unchanged
      expect(copied.type, original.type);
      expect(copied.url, original.url);
      expect(copied.tag, original.tag);
      expect(copied.autoReconnect, original.autoReconnect);
    });

    test('copyWithHeader does not mutate original', () {
      final originalHeaders = {'Accept': 'text/event-stream'};
      final original = ConnectionConfig(
        type: EventFluxConnectionType.get,
        url: 'http://example.com/sse',
        onSuccessCallback: (_) {},
        header: originalHeaders,
      );

      original.copyWithHeader({'Authorization': 'Bearer token'});

      expect(original.header, originalHeaders);
    });
  });
}
