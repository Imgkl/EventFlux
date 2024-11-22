import 'dart:async';
import 'dart:convert';

import 'package:eventflux/eventflux.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.mocks.dart';

void main() {
  late MockHttpClientAdapter mockHttpClient;
  late EventFlux eventFlux;
  const testUrl = 'http://test.com/events';

  setUp(() {
    mockHttpClient = MockHttpClientAdapter();
    eventFlux = EventFlux.spawn();
  });

  group('EventFlux', () {
    for (var connectionType in EventFluxConnectionType.values) {
      group('connect with $connectionType', () {
        test(
            'calls onSuccessCallback with connected status and streams response data',
            () async {
          final controller = StreamController<List<int>>();
          final response = StreamedResponse(
            controller.stream,
            200,
            headers: {'content-type': 'text/event-stream'},
          );

          when(mockHttpClient.send(any))
              .thenAnswer((_) => Future.value(response));

          fakeAsync((async) {
            EventFluxResponse? eventFluxResponse;
            eventFlux.connect(
              connectionType,
              testUrl,
              httpClient: mockHttpClient,
              onSuccessCallback: (res) {
                eventFluxResponse = res;
                expect(res?.status, EventFluxStatus.connected);
              },
            );

            // Simulate SSE data
            controller.add(utf8.encode('data:test message\n\n'));
            controller.add(utf8.encode('data:test message 2\n\n'));
            async.flushMicrotasks();

            final mappedStream = eventFluxResponse?.stream?.map((e) => e.data);
            expect(
                mappedStream,
                emitsInOrder([
                  'test message\n',
                  'test message 2\n',
                ]));
            async.flushMicrotasks();
          });
        });

        test('error response calls onError callback', () async {
          final response = StreamedResponse(
            Stream.value([]),
            404,
            headers: {'content-type': 'text/event-stream'},
            reasonPhrase: 'Not Found',
          );

          when(mockHttpClient.send(any))
              .thenAnswer((_) => Future.value(response));

          fakeAsync((async) {
            bool errorCaught = false;
            eventFlux.connect(
              connectionType,
              testUrl,
              httpClient: mockHttpClient,
              onSuccessCallback: (_) {},
              onError: (error) {
                errorCaught = true;
                expect(error.statusCode, 404);
                expect(error.reasonPhrase, 'Not Found');
              },
            );
            async.flushMicrotasks();

            expect(errorCaught, true);
          });
        });

        test('reconnects with autoReconnect: true for linear mode', () async {
          final controller = StreamController<List<int>>();
          final controller2 = StreamController<List<int>>();
          final response = StreamedResponse(
            controller.stream,
            200,
            headers: {'content-type': 'text/event-stream'},
          );
          final response2 = StreamedResponse(
            controller2.stream,
            200,
            headers: {'content-type': 'text/event-stream'},
          );

          final responses = [response, response2];
          when(mockHttpClient.send(any))
              .thenAnswer((_) => Future.value(responses.removeAt(0)));

          fakeAsync((async) {
            Stream<String>? mappedStream;
            eventFlux.connect(
              connectionType,
              testUrl,
              httpClient: mockHttpClient,
              autoReconnect: true,
              reconnectConfig: ReconnectConfig(
                mode: ReconnectMode.linear,
                interval: const Duration(milliseconds: 100),
                maxAttempts: 1,
              ),
              onSuccessCallback: (res) {
                mappedStream = res?.stream?.map((e) => e.data);
                expect(res?.status, EventFluxStatus.connected);
              },
            );
            async.flushMicrotasks();

            controller.add(utf8.encode('data:test message\n\n'));
            expect(mappedStream, emits('test message\n'));
            controller.close();
            async.elapse(const Duration(milliseconds: 100));

            async.flushMicrotasks();
            controller2.add(utf8.encode('data:test message 2\n\n'));
            expect(mappedStream, emits('test message 2\n'));
            controller2.close();

            async.flushMicrotasks();
          });
        });

        test('reconnects with autoReconnect: true for exponential mode',
            () async {
          final controller = StreamController<List<int>>();
          final controller2 = StreamController<List<int>>();
          final response = StreamedResponse(
            controller.stream,
            200,
            headers: {'content-type': 'text/event-stream'},
          );
          final response2 = StreamedResponse(
            controller2.stream,
            200,
            headers: {'content-type': 'text/event-stream'},
          );

          final responses = [response, response2];
          when(mockHttpClient.send(any))
              .thenAnswer((_) => Future.value(responses.removeAt(0)));

          fakeAsync((async) {
            Stream<String>? mappedStream;
            eventFlux.connect(
              connectionType,
              testUrl,
              httpClient: mockHttpClient,
              autoReconnect: true,
              reconnectConfig: ReconnectConfig(
                mode: ReconnectMode.exponential,
                interval: const Duration(seconds: 1),
                maxAttempts: 3,
              ),
              onSuccessCallback: (res) {
                mappedStream = res?.stream?.map((e) => e.data);
                expect(res?.status, EventFluxStatus.connected);
              },
            );
            async.flushMicrotasks();

            controller.add(utf8.encode('data:test message\n\n'));
            expect(mappedStream, emits('test message\n'));
            controller.close();
            async.elapse(const Duration(seconds: 1));

            async.flushMicrotasks();
            controller2.add(utf8.encode('data:test message 2\n\n'));
            expect(mappedStream, emits('test message 2\n'));
            controller2.close();

            async.flushMicrotasks();
          });
        });

        test('tries reconnection in linear intervals for linear mode',
            () async {
          final controller = StreamController<List<int>>();
          final response = StreamedResponse(
            controller.stream,
            200,
            headers: {'content-type': 'text/event-stream'},
          );

          when(mockHttpClient.send(any)).thenAnswer(
            (_) => Future.value(response),
          );

          fakeAsync((async) {
            int connectionAttempts = 0;
            eventFlux.connect(
              connectionType,
              testUrl,
              httpClient: mockHttpClient,
              autoReconnect: true,
              reconnectConfig: ReconnectConfig(
                mode: ReconnectMode.linear,
                interval: const Duration(milliseconds: 100),
                maxAttempts: 2,
                onReconnect: () {
                  connectionAttempts++;
                },
              ),
              onSuccessCallback: (_) {},
            );

            // Simulate connection close
            controller.close();
            expect(connectionAttempts, 0);
            async.elapse(const Duration(milliseconds: 100));
            expect(connectionAttempts, 1);
            async.elapse(const Duration(milliseconds: 100));
            expect(connectionAttempts, 2);
          });
        });

        test('tries reconnection in exponential intervals for exponential mode',
            () async {
          final controller = StreamController<List<int>>();
          final response = StreamedResponse(
            controller.stream,
            200,
            headers: {'content-type': 'text/event-stream'},
          );

          when(mockHttpClient.send(any)).thenAnswer(
            (_) => Future.value(response),
          );

          fakeAsync((async) {
            int connectionAttempts = 0;
            eventFlux.connect(
              connectionType,
              testUrl,
              httpClient: mockHttpClient,
              autoReconnect: true,
              reconnectConfig: ReconnectConfig(
                mode: ReconnectMode.exponential,
                interval: const Duration(seconds: 1),
                maxAttempts: 3,
                onReconnect: () {
                  connectionAttempts++;
                },
              ),
              onSuccessCallback: (_) {},
            );

            controller.close();
            expect(connectionAttempts, 0);
            async.elapse(const Duration(seconds: 1));
            expect(connectionAttempts, 1);
            async.elapse(const Duration(seconds: 2));
            expect(connectionAttempts, 2);
            async.elapse(const Duration(seconds: 4));
            expect(connectionAttempts, 3);
          });
        });
      });

      test('sends MultipartRequest with files and fields', () async {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'text/event-stream'},
        );
        final multipartFile = MultipartFile.fromString('test', 'test');
        final body = {'testKey': 'testValue'};

        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        EventFluxResponse? eventFluxResponse;
        fakeAsync((async) {
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            multipartRequest: true,
            files: [
              multipartFile,
            ],
            body: body,
            onSuccessCallback: (response) {
              eventFluxResponse = response;
            },
          );

          async.flushMicrotasks();

          final call = verify(mockHttpClient.send(captureAny))..called(1);
          final request = call.captured.single as MultipartRequest;
          expect(request.files.single, multipartFile);
          expect(request.fields, body);
          expect(eventFluxResponse?.status, EventFluxStatus.connected);
        });
      });

      test('sends multipart request with files', () async {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'text/event-stream'},
        );
        final multipartFile = MultipartFile.fromString('test', 'test');

        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        EventFluxResponse? eventFluxResponse;
        fakeAsync((async) {
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            multipartRequest: true,
            files: [multipartFile],
            onSuccessCallback: (response) {
              eventFluxResponse = response;
            },
          );
          async.flushMicrotasks();

          expect(eventFluxResponse?.status, EventFluxStatus.connected);
          final call = verify(mockHttpClient.send(captureAny))..called(1);
          final request = call.captured.single as MultipartRequest;
          expect(request.files.single, multipartFile);
        });
      });

      test('sends MultipartRequest with fields', () async {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'text/event-stream'},
        );
        final body = {'testKey': 'testValue'};

        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        EventFluxResponse? eventFluxResponse;
        fakeAsync((async) {
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            multipartRequest: true,
            body: body,
            onSuccessCallback: (response) {
              eventFluxResponse = response;
            },
          );
          async.flushMicrotasks();

          expect(eventFluxResponse?.status, EventFluxStatus.connected);
          final call = verify(mockHttpClient.send(captureAny))..called(1);
          final request = call.captured.single as MultipartRequest;
          expect(request.fields, body);
        });
      });
    }

    group('disconnect', () {
      test('explicit disconnect prevents reconnection for linear mode',
          () async {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'text/event-stream'},
        );

        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          int reconnectAttempts = 0;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            autoReconnect: true,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.linear,
              interval: const Duration(milliseconds: 100),
              maxAttempts: 2,
              onReconnect: () {
                reconnectAttempts++;
              },
            ),
            onSuccessCallback: (_) {},
          );

          final status = eventFlux.disconnect();
          expect(status, completion(EventFluxStatus.disconnected));

          async.elapse(const Duration(milliseconds: 300));
          expect(reconnectAttempts, 0);
        });
      });

      test('explicit disconnect prevents reconnection for exponential mode',
          () async {
        final controller = StreamController<List<int>>();
        final response = StreamedResponse(
          controller.stream,
          200,
          headers: {'content-type': 'text/event-stream'},
        );

        when(mockHttpClient.send(any))
            .thenAnswer((_) => Future.value(response));

        fakeAsync((async) {
          int reconnectAttempts = 0;
          eventFlux.connect(
            EventFluxConnectionType.get,
            testUrl,
            httpClient: mockHttpClient,
            autoReconnect: true,
            reconnectConfig: ReconnectConfig(
              mode: ReconnectMode.exponential,
              interval: const Duration(seconds: 1),
              maxAttempts: 2,
              onReconnect: () {
                reconnectAttempts++;
              },
            ),
            onSuccessCallback: (_) {},
          );

          final status = eventFlux.disconnect();
          expect(status, completion(EventFluxStatus.disconnected));

          async.elapse(const Duration(seconds: 3));
          expect(reconnectAttempts, 0);
        });
      });
    });
  });
}
