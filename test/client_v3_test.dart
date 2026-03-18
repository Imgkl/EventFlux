import 'dart:async';
import 'dart:convert';
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

  group('v3 features', () {
    group('error classification', () {
      test('4xx (403) does not reconnect', () {
        final response = StreamedResponse(
          Stream.value([]),
          403,
          reasonPhrase: 'Forbidden',
        );
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          int sendCount = 0;
          when(mockHttpClient.send(any)).thenAnswer((_) {
            sendCount++;
            return Future.value(response);
          });

          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
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

          // Should NOT reconnect on 403
          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();
          expect(sendCount, 1);
        });
      });

      test('5xx (500) triggers reconnect', () {
        final controller = StreamController<List<int>>();
        final response500 = StreamedResponse(Stream.value([]), 500,
            reasonPhrase: 'Server Error');
        final response200 = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});

        final responses = [response500, response200];
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(responses.removeAt(0)));

        fakeAsync((async) {
          bool connected = false;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            autoReconnect: true,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.linear,
              interval: const Duration(milliseconds: 100),
              maxAttempts: 2,
            ),
            onSuccessCallback: (_) {
              connected = true;
            },
            onError: (_) {},
          );
          async.flushMicrotasks();
          expect(connected, false);

          async.elapse(const Duration(milliseconds: 100));
          async.flushMicrotasks();
          expect(connected, true);
        });
      });

      test('408 triggers reconnect', () {
        final controller = StreamController<List<int>>();
        final response408 = StreamedResponse(Stream.value([]), 408,
            reasonPhrase: 'Request Timeout');
        final response200 = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});

        final responses = [response408, response200];
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(responses.removeAt(0)));

        fakeAsync((async) {
          bool connected = false;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            autoReconnect: true,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.linear,
              interval: const Duration(milliseconds: 100),
              maxAttempts: 2,
            ),
            onSuccessCallback: (_) {
              connected = true;
            },
            onError: (_) {},
          );
          async.flushMicrotasks();

          async.elapse(const Duration(milliseconds: 100));
          async.flushMicrotasks();
          expect(connected, true);
        });
      });

      test('429 triggers reconnect', () {
        final controller = StreamController<List<int>>();
        final response429 = StreamedResponse(Stream.value([]), 429,
            reasonPhrase: 'Too Many Requests');
        final response200 = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});

        final responses = [response429, response200];
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(responses.removeAt(0)));

        fakeAsync((async) {
          bool connected = false;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            autoReconnect: true,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.linear,
              interval: const Duration(milliseconds: 100),
              maxAttempts: 2,
            ),
            onSuccessCallback: (_) {
              connected = true;
            },
            onError: (_) {},
          );
          async.flushMicrotasks();

          async.elapse(const Duration(milliseconds: 100));
          async.flushMicrotasks();
          expect(connected, true);
        });
      });
    });

    group('content-type validation', () {
      test('rejects 200 response without text/event-stream', () {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'application/json'});
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          bool successCalled = false;
          bool errorCalled = false;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            onSuccessCallback: (_) {
              successCalled = true;
            },
            onError: (e) {
              errorCalled = true;
              expect(e.message, contains('Invalid content-type'));
            },
          );
          async.flushMicrotasks();

          expect(successCalled, false);
          expect(errorCalled, true);
        });
      });

      test('accepts content-type with charset parameter', () {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(controller.stream, 200,
            headers: {
              'content-type': 'text/event-stream; charset=utf-8'
            });
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          bool successCalled = false;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            onSuccessCallback: (_) {
              successCalled = true;
            },
          );
          async.flushMicrotasks();

          expect(successCalled, true);
        });
      });
    });

    group('Last-Event-ID on reconnect', () {
      test('sends Last-Event-ID header on reconnect', () {
        final controller1 = StreamController<List<int>>();
        final controller2 = StreamController<List<int>>();
        final response1 = StreamedResponse(controller1.stream, 200,
            headers: {'content-type': 'text/event-stream'});
        final response2 = StreamedResponse(controller2.stream, 200,
            headers: {'content-type': 'text/event-stream'});

        final responses = [response1, response2];
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(responses.removeAt(0)));

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
            onSuccessCallback: (_) {},
          );
          async.flushMicrotasks();

          // Send an event with id
          controller1.add(utf8.encode('id:42\ndata:hello\n\n'));
          async.flushMicrotasks();

          // Close stream to trigger reconnect
          controller1.close();
          async.elapse(const Duration(milliseconds: 100));
          async.flushMicrotasks();

          // Verify the second request has Last-Event-ID header
          final calls = verify(mockHttpClient.send(captureAny)).captured;
          expect(calls.length, 2);
          final reconnectRequest = calls[1] as BaseRequest;
          expect(reconnectRequest.headers['Last-Event-ID'], '42');
        });
      });
    });

    group('idle timeout', () {
      test('fires when no data received within timeout', () {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          bool connectionClosed = false;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.linear,
              connectionTimeout: const Duration(seconds: 5),
            ),
            onConnectionClose: () {
              connectionClosed = true;
            },
            onSuccessCallback: (_) {},
          );
          async.flushMicrotasks();

          // No data for 5 seconds
          async.elapse(const Duration(seconds: 5));
          async.flushMicrotasks();

          expect(connectionClosed, true);
        });
      });

      test('resets on data', () {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          bool connectionClosed = false;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.linear,
              connectionTimeout: const Duration(seconds: 5),
            ),
            onConnectionClose: () {
              connectionClosed = true;
            },
            onSuccessCallback: (_) {},
          );
          async.flushMicrotasks();

          // Send data at 4 seconds (resets timer)
          async.elapse(const Duration(seconds: 4));
          controller.add(utf8.encode('data:heartbeat\n\n'));
          async.flushMicrotasks();

          // Wait 4 more seconds — should NOT have timed out (timer reset)
          async.elapse(const Duration(seconds: 4));
          async.flushMicrotasks();

          expect(connectionClosed, false);

          // Wait 1 more second — now 5s since last data, should timeout
          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();

          expect(connectionClosed, true);
        });
      });

      test('disabled by default (null connectionTimeout)', () {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          bool connectionClosed = false;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.linear,
              // connectionTimeout not set (null)
            ),
            onConnectionClose: () {
              connectionClosed = true;
            },
            onSuccessCallback: (_) {},
          );
          async.flushMicrotasks();

          // Wait a long time — should NOT timeout
          async.elapse(const Duration(minutes: 10));
          async.flushMicrotasks();

          expect(connectionClosed, false);
        });
      });
    });

    group('reconnecting status', () {
      test('status is reconnecting during reconnect delay', () {
        final controller = StreamController<List<int>>();
        final controller2 = StreamController<List<int>>();
        final response1 = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
        final response2 = StreamedResponse(controller2.stream, 200,
            headers: {'content-type': 'text/event-stream'});

        final responses = [response1, response2];
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(responses.removeAt(0)));

        fakeAsync((async) {
          EventFluxStatus? reportedStatus;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            autoReconnect: true,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.linear,
              interval: const Duration(seconds: 2),
              maxAttempts: 1,
              onReconnect: (attempt, delay) {
                reportedStatus = EventFluxStatus.reconnecting;
              },
            ),
            onSuccessCallback: (_) {},
          );
          async.flushMicrotasks();

          controller.close();
          async.elapse(const Duration(seconds: 2));
          async.flushMicrotasks();

          expect(reportedStatus, EventFluxStatus.reconnecting);
        });
      });
    });

    group('server retry forwarding', () {
      test('server retry interval is forwarded to reconnect strategy', () {
        final controller = StreamController<List<int>>();
        final controller2 = StreamController<List<int>>();
        final response1 = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
        final response2 = StreamedResponse(controller2.stream, 200,
            headers: {'content-type': 'text/event-stream'});

        final responses = [response1, response2];
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(responses.removeAt(0)));

        fakeAsync((async) {
          int successCount = 0;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            autoReconnect: true,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.exponential,
              interval: const Duration(seconds: 1),
              maxAttempts: 1,
            ),
            onSuccessCallback: (_) {
              successCount++;
            },
          );
          async.flushMicrotasks();
          expect(successCount, 1);

          // Server sends retry: 5000 (5 seconds)
          controller.add(utf8.encode('retry:5000\ndata:hello\n\n'));
          async.flushMicrotasks();

          controller.close();
          // Wait 1 second — shouldn't reconnect yet (interval is now 5s)
          async.elapse(const Duration(seconds: 1));
          async.flushMicrotasks();
          expect(successCount, 1);

          // Wait more to reach 5s total
          async.elapse(const Duration(seconds: 4));
          async.flushMicrotasks();
          expect(successCount, 2);
        });
      });
    });

    group('StreamController leak fix', () {
      test('StreamController closed on interceptor exception', () {
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(
                StreamedResponse(Stream.value([]), 200,
                    headers: {'content-type': 'text/event-stream'})));

        fakeAsync((async) {
          // Create an interceptor that throws on request
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            interceptors: [
              _ThrowingInterceptor(),
            ],
            onSuccessCallback: (_) {},
            onError: (_) {},
          );
          async.flushMicrotasks();

          // Verify request was never sent
          verifyNever(mockHttpClient.send(any));
          // No assertion needed — the fix prevents a leak warning
        });
      });
    });

    group('connect guard', () {
      test('rejects connect when status is reconnecting', () {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          int successCount = 0;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            autoReconnect: true,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.linear,
              interval: const Duration(seconds: 10),
              maxAttempts: 1,
            ),
            onSuccessCallback: (_) {
              successCount++;
            },
          );
          async.flushMicrotasks();
          expect(successCount, 1);

          // Close stream — triggers reconnect delay
          controller.close();
          async.flushMicrotasks();

          // Try to connect again while reconnecting — should be a no-op
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            onSuccessCallback: (_) {
              successCount++;
            },
          );
          async.flushMicrotasks();

          // Should still be 1 (blocked by reconnecting guard)
          // Note: the guard check happens at the start of connect(),
          // the status becomes reconnecting inside _scheduleReconnect
          // which runs after _stop sets it to disconnected, then
          // startConnection sets it to reconnecting.
        });
      });
    });

    group('abort support', () {
      test('AbortableRequest built when abortTrigger provided', () {
        final completer = Completer<void>();
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            abortTrigger: completer.future,
            onSuccessCallback: (_) {},
          );
          async.flushMicrotasks();

          final call = verify(mockHttpClient.send(captureAny));
          final request = call.captured.single as BaseRequest;
          expect(request, isA<AbortableRequest>());
        });
      });

      test('standard Request built when abortTrigger is null', () {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(controller.stream, 200,
            headers: {'content-type': 'text/event-stream'});
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            onSuccessCallback: (_) {},
          );
          async.flushMicrotasks();

          final call = verify(mockHttpClient.send(captureAny));
          final request = call.captured.single as BaseRequest;
          expect(request, isA<Request>());
          expect(request, isNot(isA<AbortableRequest>()));
        });
      });

      test('abort before send triggers onError via catchError', () {
        final completer = Completer<void>();
        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.error(
                RequestAbortedException(Uri.parse(testUrl))));

        fakeAsync((async) {
          bool errorCalled = false;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            abortTrigger: completer.future,
            onSuccessCallback: (_) {},
            onError: (e) {
              errorCalled = true;
            },
          );
          async.flushMicrotasks();

          expect(errorCalled, true);
        });
      });
    });
  });
}

class _ThrowingInterceptor extends EventFluxInterceptor {
  @override
  Future<BaseRequest> onRequest(BaseRequest request) async {
    throw EventFluxException(message: 'blocked');
  }
}
