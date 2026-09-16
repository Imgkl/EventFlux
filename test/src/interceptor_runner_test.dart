import 'package:eventflux/models/exception.dart';
import 'package:eventflux/models/interceptor.dart';
import 'package:eventflux/src/interceptor_runner.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

class _TestInterceptor extends EventFluxInterceptor {
  final Future<BaseRequest> Function(BaseRequest)? onRequestFn;
  final Future<StreamedResponse> Function(StreamedResponse)? onResponseFn;
  final Future<EventFluxException?> Function(EventFluxException)? onErrorFn;

  _TestInterceptor({this.onRequestFn, this.onResponseFn, this.onErrorFn});

  @override
  Future<BaseRequest> onRequest(BaseRequest request) async {
    if (onRequestFn != null) return onRequestFn!(request);
    return request;
  }

  @override
  Future<StreamedResponse> onResponse(StreamedResponse response) async {
    if (onResponseFn != null) return onResponseFn!(response);
    return response;
  }

  @override
  Future<EventFluxException?> onError(EventFluxException exception) async {
    if (onErrorFn != null) return onErrorFn!(exception);
    return exception;
  }
}

void main() {
  group('InterceptorRunner', () {
    group('runOnRequest', () {
      test('returns original request when interceptors is null', () async {
        final request = Request('GET', Uri.parse('http://example.com'));
        final result = await InterceptorRunner.runOnRequest(request, null);
        expect(identical(result, request), true);
      });

      test('chains multiple interceptors in order', () async {
        final order = <int>[];
        final interceptors = [
          _TestInterceptor(onRequestFn: (r) async {
            order.add(1);
            r.headers['X-First'] = 'true';
            return r;
          }),
          _TestInterceptor(onRequestFn: (r) async {
            order.add(2);
            r.headers['X-Second'] = 'true';
            return r;
          }),
        ];

        final request = Request('GET', Uri.parse('http://example.com'));
        final result =
            await InterceptorRunner.runOnRequest(request, interceptors);

        expect(order, [1, 2]);
        expect(result.headers['X-First'], 'true');
        expect(result.headers['X-Second'], 'true');
      });

      test('propagates EventFluxException from interceptor', () async {
        final interceptors = [
          _TestInterceptor(onRequestFn: (r) async {
            throw EventFluxException(message: 'blocked');
          }),
        ];

        final request = Request('GET', Uri.parse('http://example.com'));
        expect(
          () => InterceptorRunner.runOnRequest(request, interceptors),
          throwsA(isA<EventFluxException>()),
        );
      });
    });

    group('runOnResponse', () {
      test('returns original response when interceptors is null', () async {
        final response = StreamedResponse(Stream.value([]), 200);
        final result = await InterceptorRunner.runOnResponse(response, null);
        expect(identical(result, response), true);
      });

      test('chains multiple response interceptors', () async {
        int callCount = 0;
        final interceptors = [
          _TestInterceptor(onResponseFn: (r) async {
            callCount++;
            return r;
          }),
          _TestInterceptor(onResponseFn: (r) async {
            callCount++;
            return r;
          }),
        ];

        final response = StreamedResponse(Stream.value([]), 200);
        await InterceptorRunner.runOnResponse(response, interceptors);
        expect(callCount, 2);
      });
    });

    group('runOnError', () {
      test('calls user onError when interceptors is null', () async {
        bool called = false;
        final exception = EventFluxException(message: 'test');
        await InterceptorRunner.runOnError(exception, null, (e) {
          called = true;
        });
        expect(called, true);
      });

      test('calls user onError when interceptors is empty', () async {
        bool called = false;
        final exception = EventFluxException(message: 'test');
        await InterceptorRunner.runOnError(exception, [], (e) {
          called = true;
        });
        expect(called, true);
      });

      test('suppresses user onError when interceptor returns null', () async {
        bool called = false;
        final interceptors = [
          _TestInterceptor(onErrorFn: (e) async => null),
        ];
        final exception = EventFluxException(message: 'test');
        await InterceptorRunner.runOnError(exception, interceptors, (e) {
          called = true;
        });
        expect(called, false);
      });

      test('stops chain when interceptor returns null', () async {
        int callCount = 0;
        final interceptors = [
          _TestInterceptor(onErrorFn: (e) async {
            callCount++;
            return null;
          }),
          _TestInterceptor(onErrorFn: (e) async {
            callCount++;
            return e;
          }),
        ];
        final exception = EventFluxException(message: 'test');
        await InterceptorRunner.runOnError(exception, interceptors, (_) {});
        expect(callCount, 1);
      });

      test('transforms exception through chain', () async {
        EventFluxException? received;
        final interceptors = [
          _TestInterceptor(
            onErrorFn: (e) async =>
                EventFluxException(message: 'transformed: ${e.message}'),
          ),
        ];
        final exception = EventFluxException(message: 'original');
        await InterceptorRunner.runOnError(exception, interceptors, (e) {
          received = e;
        });
        expect(received!.message, 'transformed: original');
      });
    });
  });
}
