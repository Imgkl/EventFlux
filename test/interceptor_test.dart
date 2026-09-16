import 'dart:async';
import 'dart:math';

import 'package:eventflux/eventflux.dart';
import 'package:eventflux/src/reconnect_strategy.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.mocks.dart';

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
class TestInterceptor extends EventFluxInterceptor {
  final List<String> calls = [];
  final Future<BaseRequest> Function(BaseRequest)? onRequestFn;
  final Future<StreamedResponse> Function(StreamedResponse)? onResponseFn;
  final Future<EventFluxException?> Function(EventFluxException)? onErrorFn;

  TestInterceptor({this.onRequestFn, this.onResponseFn, this.onErrorFn});

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

void main() {
  late MockHttpClientAdapter mockHttpClient;
  late EventFlux eventFlux;
  const testUrl = 'http://test.com/events';

  setUp(() {
    mockHttpClient = MockHttpClientAdapter();
    eventFlux = EventFlux.spawn();
    ReconnectStrategy.random = _ZeroRandom();
  });

  tearDown(() {
    ReconnectStrategy.random = Random();
  });

  group('Interceptors', () {
    test('onRequest modifies headers before sending', () {
      final controller = StreamController<List<int>>();
      final response = StreamedResponse(controller.stream, 200,
          headers: {'content-type': 'text/event-stream'});
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      final interceptor = TestInterceptor(
        onRequestFn: (request) async {
          request.headers['Authorization'] = 'Bearer test-token';
          return request;
        },
      );

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
        );
        async.flushMicrotasks();
      });

      final call = verify(mockHttpClient.send(captureAny))..called(1);
      final request = call.captured.single as BaseRequest;
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(interceptor.calls, contains('onRequest'));
    });

    test('multiple interceptors run in declared order', () {
      final controller = StreamController<List<int>>();
      final response = StreamedResponse(controller.stream, 200,
          headers: {'content-type': 'text/event-stream'});
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      final order = <String>[];
      final interceptor1 = TestInterceptor(
        onRequestFn: (request) async {
          order.add('first');
          return request;
        },
      );
      final interceptor2 = TestInterceptor(
        onRequestFn: (request) async {
          order.add('second');
          return request;
        },
      );

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor1, interceptor2],
          onSuccessCallback: (_) {},
        );
        async.flushMicrotasks();
      });

      expect(order, ['first', 'second']);
    });

    test('onResponse called on 200 response', () {
      final controller = StreamController<List<int>>();
      final response = StreamedResponse(controller.stream, 200,
          headers: {'content-type': 'text/event-stream'});
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      final interceptor = TestInterceptor();

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
        );
        async.flushMicrotasks();
      });

      expect(
          interceptor.calls, containsAllInOrder(['onRequest', 'onResponse']));
    });

    test('onResponse called on non-200 response before error chain', () {
      final response =
          StreamedResponse(Stream.value([]), 401, reasonPhrase: 'Unauthorized');
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      final interceptor = TestInterceptor();

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
          onError: (_) {},
        );
        async.flushMicrotasks();
      });

      // onResponse should be called before onError
      expect(interceptor.calls,
          containsAllInOrder(['onRequest', 'onResponse', 'onError']));
    });

    test('onError called on non-200 status with correct status code', () {
      final response = StreamedResponse(Stream.value([]), 500,
          reasonPhrase: 'Internal Server Error');
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      EventFluxException? receivedError;
      final interceptor = TestInterceptor(
        onErrorFn: (exception) async {
          receivedError = exception;
          return exception;
        },
      );

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
          onError: (_) {},
        );
        async.flushMicrotasks();
      });

      expect(receivedError, isNotNull);
      expect(receivedError!.statusCode, 500);
    });

    test('onError called on send failure', () {
      when(mockHttpClient.send(any))
          .thenAnswer((_) => Future.error(Exception('network failure')));

      final interceptor = TestInterceptor();

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
          onError: (_) {},
        );
        async.flushMicrotasks();
      });

      expect(interceptor.calls, contains('onError'));
    });

    test('onError returning null suppresses user onError callback', () {
      final response =
          StreamedResponse(Stream.value([]), 403, reasonPhrase: 'Forbidden');
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      final interceptor = TestInterceptor(
        onErrorFn: (exception) async => null, // suppress
      );

      fakeAsync((async) {
        bool userOnErrorCalled = false;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
          onError: (_) {
            userOnErrorCalled = true;
          },
        );
        async.flushMicrotasks();

        expect(userOnErrorCalled, false);
      });
    });

    test('onError returning exception propagates to user onError callback', () {
      final response =
          StreamedResponse(Stream.value([]), 403, reasonPhrase: 'Forbidden');
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      final interceptor = TestInterceptor(); // default: pass through

      fakeAsync((async) {
        bool userOnErrorCalled = false;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
          onError: (_) {
            userOnErrorCalled = true;
          },
        );
        async.flushMicrotasks();

        expect(userOnErrorCalled, true);
      });
    });

    test(
        'onRequest throwing EventFluxException short-circuits — request never sent',
        () {
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(
          StreamedResponse(Stream.value([]), 200,
              headers: {'content-type': 'text/event-stream'})));

      final interceptor = TestInterceptor(
        onRequestFn: (request) async {
          throw EventFluxException(message: 'blocked by interceptor');
        },
      );

      fakeAsync((async) {
        EventFluxException? receivedError;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
          onError: (e) {
            receivedError = e;
          },
        );
        async.flushMicrotasks();

        // Request should never have been sent
        verifyNever(mockHttpClient.send(any));
        // Error callback should have fired via the error interceptor chain
        expect(receivedError, isNotNull);
        expect(receivedError!.message, 'blocked by interceptor');
      });
    });

    test('onRequest throw runs onError interceptors before user callback', () {
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(
          StreamedResponse(Stream.value([]), 200,
              headers: {'content-type': 'text/event-stream'})));

      final errorInterceptor = TestInterceptor(
        onRequestFn: (request) async => request, // pass-through
        onErrorFn: (exception) async {
          // Transform the error message
          return EventFluxException(
              message: 'transformed: ${exception.message}');
        },
      );

      final throwingInterceptor = TestInterceptor(
        onRequestFn: (request) async {
          throw EventFluxException(message: 'original');
        },
      );

      fakeAsync((async) {
        EventFluxException? receivedError;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [throwingInterceptor, errorInterceptor],
          onSuccessCallback: (_) {},
          onError: (e) {
            receivedError = e;
          },
        );
        async.flushMicrotasks();

        expect(receivedError, isNotNull);
        expect(receivedError!.message, 'transformed: original');
      });
    });

    test('interceptors fire again on reconnection attempts', () {
      final controller1 = StreamController<List<int>>();
      final controller2 = StreamController<List<int>>();
      final response1 = StreamedResponse(controller1.stream, 200,
          headers: {'content-type': 'text/event-stream'});
      final response2 = StreamedResponse(controller2.stream, 200,
          headers: {'content-type': 'text/event-stream'});

      final responses = [response1, response2];
      when(mockHttpClient.send(any))
          .thenAnswer((_) => Future.value(responses.removeAt(0)));

      final interceptor = TestInterceptor();

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          autoReconnect: true,
          reconnectConfig: ReconnectConfig(
            mode: ReconnectMode.linear,
            interval: const Duration(milliseconds: 100),
            maxAttempts: 1,
          ),
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
        );
        async.flushMicrotasks();

        // First connection: onRequest + onResponse
        expect(interceptor.calls.where((c) => c == 'onRequest').length, 1);

        // Close stream to trigger reconnection
        controller1.close();
        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();

        // After reconnection: onRequest called again
        expect(interceptor.calls.where((c) => c == 'onRequest').length, 2);
      });
    });

    test('null interceptors list is backward-compatible', () {
      final controller = StreamController<List<int>>();
      final response = StreamedResponse(controller.stream, 200,
          headers: {'content-type': 'text/event-stream'});
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      fakeAsync((async) {
        EventFluxResponse? result;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          // interceptors not passed (null)
          onSuccessCallback: (res) {
            result = res;
          },
        );
        async.flushMicrotasks();

        expect(result?.status, EventFluxStatus.connected);
      });
    });

    test('empty interceptors list is backward-compatible', () {
      final controller = StreamController<List<int>>();
      final response = StreamedResponse(controller.stream, 200,
          headers: {'content-type': 'text/event-stream'});
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      fakeAsync((async) {
        EventFluxResponse? result;
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [],
          onSuccessCallback: (res) {
            result = res;
          },
        );
        async.flushMicrotasks();

        expect(result?.status, EventFluxStatus.connected);
      });
    });

    test('error chain stops when an interceptor returns null', () {
      final response =
          StreamedResponse(Stream.value([]), 500, reasonPhrase: 'Server Error');
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      final interceptor1 = TestInterceptor(
        onErrorFn: (exception) async => null, // suppress
      );
      final interceptor2 = TestInterceptor();

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor1, interceptor2],
          onSuccessCallback: (_) {},
          onError: (_) {},
        );
        async.flushMicrotasks();
      });

      // First interceptor was called
      expect(interceptor1.calls, contains('onError'));
      // Second interceptor's onError should NOT be called (chain broke)
      expect(interceptor2.calls.where((c) => c == 'onError').length, 0);
    });

    test('onResponse can inspect non-200 response headers', () {
      final response = StreamedResponse(
        Stream.value([]),
        429,
        reasonPhrase: 'Too Many Requests',
        headers: {'retry-after': '30'},
      );
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      String? retryAfter;
      final interceptor = TestInterceptor(
        onResponseFn: (response) async {
          retryAfter = response.headers['retry-after'];
          return response;
        },
      );

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [interceptor],
          onSuccessCallback: (_) {},
          onError: (_) {},
        );
        async.flushMicrotasks();
      });

      expect(retryAfter, '30');
    });

    test('multiple onRequest interceptors chain modifications', () {
      final controller = StreamController<List<int>>();
      final response = StreamedResponse(controller.stream, 200,
          headers: {'content-type': 'text/event-stream'});
      when(mockHttpClient.send(any)).thenAnswer((_) => Future.value(response));

      final authInterceptor = TestInterceptor(
        onRequestFn: (request) async {
          request.headers['Authorization'] = 'Bearer token';
          return request;
        },
      );
      final loggingInterceptor = TestInterceptor(
        onRequestFn: (request) async {
          request.headers['X-Request-Id'] = 'req-123';
          return request;
        },
      );

      fakeAsync((async) {
        eventFlux.connect(
          EventFluxConnectionType.get,
          testUrl,
          httpClient: mockHttpClient,
          interceptors: [authInterceptor, loggingInterceptor],
          onSuccessCallback: (_) {},
        );
        async.flushMicrotasks();
      });

      final call = verify(mockHttpClient.send(captureAny))..called(1);
      final request = call.captured.single as BaseRequest;
      expect(request.headers['Authorization'], 'Bearer token');
      expect(request.headers['X-Request-Id'], 'req-123');
    });
  });
}
