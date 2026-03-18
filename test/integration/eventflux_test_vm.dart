@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:eventflux/eventflux.dart';
import 'package:eventflux/src/reconnect_strategy.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mocks.mocks.dart';

/// A [Random] that always returns 0 from [nextDouble], eliminating jitter.
class _ZeroRandom implements Random {
  @override
  double nextDouble() => 0.0;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

/// A concrete test interceptor that records calls and allows custom behavior.
class _TestInterceptor extends EventFluxInterceptor {
  final List<String> calls = [];
  final Future<BaseRequest> Function(BaseRequest)? onRequestFn;
  final Future<StreamedResponse> Function(StreamedResponse)? onResponseFn;
  final Future<EventFluxException?> Function(EventFluxException)? onErrorFn;

  _TestInterceptor({this.onRequestFn, this.onResponseFn, this.onErrorFn});

  @override
  Future<BaseRequest> onRequest(BaseRequest request) async {
    calls.add('onRequest');
    if (onRequestFn != null) return onRequestFn!(request);
    return request;
  }

  @override
  Future<StreamedResponse> onResponse(StreamedResponse response) async {
    calls.add('onResponse');
    if (onResponseFn != null) return onResponseFn!(response);
    return response;
  }

  @override
  Future<EventFluxException?> onError(EventFluxException exception) async {
    calls.add('onError');
    if (onErrorFn != null) return onErrorFn!(exception);
    return exception;
  }
}

/// Creates a [StreamedResponse] with `text/event-stream` content-type.
StreamedResponse _sseResponse(Stream<List<int>> body, {int statusCode = 200}) {
  return StreamedResponse(
    body,
    statusCode,
    headers: {'content-type': 'text/event-stream'},
  );
}

void main() {
  late MockHttpClientAdapter mockAdapter;
  late EventFlux eventFlux;
  const testUrl = 'http://test.com/events';

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    eventFlux = EventFlux.spawn();
    ReconnectStrategy.random = _ZeroRandom();
  });

  tearDown(() {
    ReconnectStrategy.random = Random();
  });

  group('Integration: full connect -> parse -> deliver flow', () {
    test('multi-event SSE stream with id, event, data fields parsed correctly',
        () {
      final controller = StreamController<List<int>>();
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(_sseResponse(controller.stream)));

      fakeAsync((async) {
        EventFluxResponse? result;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          onSuccessCallback: (res) {
            result = res;
          },
        );
        async.flushMicrotasks();

        expect(result, isNotNull);
        expect(result!.status, EventFluxStatus.connected);

        final events = <EventFluxData>[];
        result!.stream!.listen(events.add);

        // Send multiple SSE events with id, event, and data fields
        controller.add(utf8.encode('id:1\nevent:message\ndata:hello\n\n'));
        controller.add(utf8.encode('id:2\nevent:update\ndata:world\n\n'));
        controller
            .add(utf8.encode('id:3\nevent:message\ndata:multi line\n\n'));
        async.flushMicrotasks();

        expect(events.length, 3);

        expect(events[0].id, '1');
        expect(events[0].event, 'message');
        expect(events[0].data, 'hello');

        expect(events[1].id, '2');
        expect(events[1].event, 'update');
        expect(events[1].data, 'world');

        expect(events[2].id, '3');
        expect(events[2].event, 'message');
        expect(events[2].data, 'multi line');
      });
    });

    test('POST connection with body delivers events, request body verified',
        () {
      final controller = StreamController<List<int>>();
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(_sseResponse(controller.stream)));

      fakeAsync((async) {
        EventFluxResponse? result;
        eventFlux.connect(
          EventFluxConnectionType.post,
          testUrl,
          httpClient: mockAdapter,
          body: {'key': 'value'},
          onSuccessCallback: (res) {
            result = res;
          },
        );
        async.flushMicrotasks();

        // Verify the request was POST with correct body
        final call = verify(mockAdapter.send(captureAny))..called(1);
        final request = call.captured.single as Request;
        expect(request.method, 'POST');
        expect(request.body, '{"key":"value"}');

        // Verify events are delivered
        final events = <EventFluxData>[];
        result!.stream!.listen(events.add);

        controller.add(utf8.encode('data:response data\n\n'));
        async.flushMicrotasks();

        expect(events.length, 1);
        expect(events[0].data, 'response data');
      });
    });
  });

  group('Integration: reconnection flow', () {
    test('500 error triggers reconnect, second attempt succeeds with events',
        () {
      final controller = StreamController<List<int>>();
      final response500 = StreamedResponse(
        Stream.value([]),
        500,
        reasonPhrase: 'Internal Server Error',
      );
      final response200 = _sseResponse(controller.stream);

      final responses = [response500, response200];
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(responses.removeAt(0)));

      fakeAsync((async) {
        EventFluxResponse? result;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          autoReconnect: true,
          reconnectConfig: ReconnectConfig(
            mode: ReconnectMode.linear,
            interval: const Duration(milliseconds: 200),
            maxAttempts: 2,
          ),
          onSuccessCallback: (res) {
            result = res;
          },
          onError: (_) {},
        );
        async.flushMicrotasks();

        // First attempt got 500, should not be connected yet
        expect(result, isNull);

        // Elapse reconnect interval
        async.elapse(const Duration(milliseconds: 200));
        async.flushMicrotasks();

        // Second attempt succeeds
        expect(result, isNotNull);
        expect(result!.status, EventFluxStatus.connected);

        // Verify events are delivered on the new connection
        final events = <EventFluxData>[];
        result!.stream!.listen(events.add);

        controller.add(utf8.encode('data:after reconnect\n\n'));
        async.flushMicrotasks();

        expect(events.length, 1);
        expect(events[0].data, 'after reconnect');
      });
    });

    test('stream close injects Last-Event-ID header on reconnect', () {
      final controller1 = StreamController<List<int>>();
      final controller2 = StreamController<List<int>>();
      final response1 = _sseResponse(controller1.stream);
      final response2 = _sseResponse(controller2.stream);

      final responses = [response1, response2];
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(responses.removeAt(0)));

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          autoReconnect: true,
          reconnectConfig: ReconnectConfig(
            mode: ReconnectMode.linear,
            interval: const Duration(milliseconds: 100),
            maxAttempts: 1,
          ),
          onSuccessCallback: (_) {},
        );
        async.flushMicrotasks();

        // Send event with id, then close stream
        controller1.add(utf8.encode('id:evt-99\ndata:payload\n\n'));
        async.flushMicrotasks();

        controller1.close();
        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();

        // Verify reconnect request has Last-Event-ID
        final calls = verify(mockAdapter.send(captureAny)).captured;
        expect(calls.length, 2);
        final reconnectRequest = calls[1] as BaseRequest;
        expect(reconnectRequest.headers['Last-Event-ID'], 'evt-99');
      });
    });

    test('403 error does NOT trigger reconnect even with autoReconnect: true',
        () {
      final response403 = StreamedResponse(
        Stream.value([]),
        403,
        reasonPhrase: 'Forbidden',
      );

      int sendCount = 0;
      when(mockAdapter.send(any)).thenAnswer((_) {
        sendCount++;
        return Future.value(response403);
      });

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          autoReconnect: true,
          reconnectConfig: ReconnectConfig(
            mode: ReconnectMode.linear,
            interval: const Duration(milliseconds: 100),
            maxAttempts: 3,
          ),
          onSuccessCallback: (_) {},
          onError: (_) {},
        );
        async.flushMicrotasks();

        // Wait well past reconnect interval — should NOT retry
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(sendCount, 1);
      });
    });
  });

  group('Integration: interceptor integration', () {
    test(
        'onRequest adds auth header, onResponse sees status, events delivered',
        () {
      final controller = StreamController<List<int>>();
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(_sseResponse(controller.stream)));

      int? seenStatus;
      final interceptor = _TestInterceptor(
        onRequestFn: (request) async {
          request.headers['Authorization'] = 'Bearer my-token';
          return request;
        },
        onResponseFn: (response) async {
          seenStatus = response.statusCode;
          return response;
        },
      );

      fakeAsync((async) {
        EventFluxResponse? result;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          interceptors: [interceptor],
          onSuccessCallback: (res) {
            result = res;
          },
        );
        async.flushMicrotasks();

        // Verify auth header was added
        final call = verify(mockAdapter.send(captureAny))..called(1);
        final request = call.captured.single as BaseRequest;
        expect(request.headers['Authorization'], 'Bearer my-token');

        // Verify onResponse saw status 200
        expect(seenStatus, 200);

        // Verify events still flow through
        final events = <EventFluxData>[];
        result!.stream!.listen(events.add);

        controller.add(utf8.encode('data:intercepted event\n\n'));
        async.flushMicrotasks();

        expect(events.length, 1);
        expect(events[0].data, 'intercepted event');

        expect(interceptor.calls,
            containsAllInOrder(['onRequest', 'onResponse']));
      });
    });

    test(
        'onError returning null suppresses user callback but reconnect still proceeds',
        () {
      final controller = StreamController<List<int>>();
      final response500 = StreamedResponse(
        Stream.value([]),
        500,
        reasonPhrase: 'Server Error',
      );
      final response200 = _sseResponse(controller.stream);

      final responses = [response500, response200];
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(responses.removeAt(0)));

      final interceptor = _TestInterceptor(
        onErrorFn: (exception) async => null, // suppress
      );

      fakeAsync((async) {
        bool userErrorCalled = false;
        bool connected = false;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          autoReconnect: true,
          reconnectConfig: ReconnectConfig(
            mode: ReconnectMode.linear,
            interval: const Duration(milliseconds: 100),
            maxAttempts: 2,
          ),
          interceptors: [interceptor],
          onSuccessCallback: (res) {
            connected = true;
          },
          onError: (_) {
            userErrorCalled = true;
          },
        );
        async.flushMicrotasks();

        // User onError should have been suppressed
        expect(userErrorCalled, false);
        expect(interceptor.calls, contains('onError'));

        // Reconnect should still proceed
        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();
        expect(connected, true);
      });
    });
  });

  group('Integration: disconnect flow', () {
    test('connect, receive events, disconnect, verify no reconnection', () {
      final controller = StreamController<List<int>>();
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(_sseResponse(controller.stream)));

      fakeAsync((async) {
        EventFluxResponse? result;
        int successCount = 0;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          autoReconnect: true,
          reconnectConfig: ReconnectConfig(
            mode: ReconnectMode.linear,
            interval: const Duration(milliseconds: 100),
            maxAttempts: 3,
          ),
          onSuccessCallback: (res) {
            result = res;
            successCount++;
          },
        );
        async.flushMicrotasks();

        expect(result, isNotNull);
        expect(successCount, 1);

        // Receive some events
        final events = <EventFluxData>[];
        result!.stream!.listen(events.add);

        controller.add(utf8.encode('data:event 1\n\n'));
        controller.add(utf8.encode('data:event 2\n\n'));
        async.flushMicrotasks();
        expect(events.length, 2);

        // Explicit disconnect
        eventFlux.disconnect();
        async.flushMicrotasks();

        // Wait past reconnect interval — should NOT reconnect
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(successCount, 1);
      });
    });

    test('disconnect during reconnect delay cancels pending reconnect', () {
      final controller = StreamController<List<int>>();
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(_sseResponse(controller.stream)));

      int sendCount = 0;
      when(mockAdapter.send(any)).thenAnswer((_) {
        sendCount++;
        return Future.value(_sseResponse(controller.stream));
      });

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          autoReconnect: true,
          reconnectConfig: ReconnectConfig(
            mode: ReconnectMode.linear,
            interval: const Duration(seconds: 5),
            maxAttempts: 3,
          ),
          onSuccessCallback: (_) {},
        );
        async.flushMicrotasks();
        expect(sendCount, 1);

        // Close stream to trigger reconnection delay
        controller.close();
        async.flushMicrotasks();

        // Disconnect during the delay
        eventFlux.disconnect();
        async.flushMicrotasks();

        // Elapse past interval — should NOT reconnect
        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();
        expect(sendCount, 1);
      });
    });
  });

  group('Integration: event filtering via where()', () {
    test('mixed event types, where(update) returns only matching events', () {
      final controller = StreamController<List<int>>();
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(_sseResponse(controller.stream)));

      fakeAsync((async) {
        EventFluxResponse? result;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          onSuccessCallback: (res) {
            result = res;
          },
        );
        async.flushMicrotasks();

        final updateEvents = <EventFluxData>[];
        result!.where('update').listen(updateEvents.add);

        // Send mixed event types
        controller.add(utf8.encode('event:message\ndata:msg1\n\n'));
        controller.add(utf8.encode('event:update\ndata:upd1\n\n'));
        controller.add(utf8.encode('event:message\ndata:msg2\n\n'));
        controller.add(utf8.encode('event:update\ndata:upd2\n\n'));
        controller.add(utf8.encode('event:delete\ndata:del1\n\n'));
        async.flushMicrotasks();

        expect(updateEvents.length, 2);
        expect(updateEvents[0].data, 'upd1');
        expect(updateEvents[1].data, 'upd2');
      });
    });
  });

  group('Integration: idle timeout with reconnect', () {
    test(
        'server goes silent after one event, connectionTimeout triggers reconnect, new connection delivers events',
        () {
      final controller1 = StreamController<List<int>>();
      final controller2 = StreamController<List<int>>();
      final response1 = _sseResponse(controller1.stream);
      final response2 = _sseResponse(controller2.stream);

      final responses = [response1, response2];
      when(mockAdapter.send(any))
          .thenAnswer((_) => Future.value(responses.removeAt(0)));

      fakeAsync((async) {
        int successCount = 0;
        EventFluxResponse? result;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockAdapter,
          autoReconnect: true,
          reconnectConfig: ReconnectConfig(
            mode: ReconnectMode.linear,
            interval: const Duration(milliseconds: 100),
            connectionTimeout: const Duration(seconds: 3),
            maxAttempts: 1,
          ),
          onSuccessCallback: (res) {
            result = res;
            successCount++;
          },
        );
        async.flushMicrotasks();
        expect(successCount, 1);

        // Send one event, then go silent
        controller1.add(utf8.encode('data:first\n\n'));
        async.flushMicrotasks();

        // Wait for idle timeout (3s from last data)
        async.elapse(const Duration(seconds: 3));
        async.flushMicrotasks();

        // Elapse reconnect interval
        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();

        // Should have reconnected
        expect(successCount, 2);

        // New connection delivers events
        final events = <EventFluxData>[];
        result!.stream!.listen(events.add);

        controller2.add(utf8.encode('data:second\n\n'));
        async.flushMicrotasks();

        expect(events.length, 1);
        expect(events[0].data, 'second');
      });
    });
  });
}
