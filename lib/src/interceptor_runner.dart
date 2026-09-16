import 'package:eventflux/models/exception.dart';
import 'package:eventflux/models/interceptor.dart';
import 'package:http/http.dart';

/// Stateless interceptor chain executor.
///
/// Consolidates the three scattered interceptor loops from `_start()` and
/// `_runErrorInterceptors()` into a single utility class.
class InterceptorRunner {
  const InterceptorRunner._();

  /// Runs the `onRequest` interceptor chain.
  ///
  /// Each interceptor may modify the [request]. If any interceptor throws an
  /// [EventFluxException], the chain is aborted and the exception propagates.
  static Future<BaseRequest> runOnRequest(
    BaseRequest request,
    List<EventFluxInterceptor>? interceptors,
  ) async {
    if (interceptors == null) return request;
    for (final interceptor in interceptors) {
      request = await interceptor.onRequest(request);
    }
    return request;
  }

  /// Runs the `onResponse` interceptor chain.
  ///
  /// Each interceptor may inspect (but must NOT consume the body of) the
  /// [response].
  static Future<StreamedResponse> runOnResponse(
    StreamedResponse response,
    List<EventFluxInterceptor>? interceptors,
  ) async {
    if (interceptors == null) return response;
    for (final interceptor in interceptors) {
      response = await interceptor.onResponse(response);
    }
    return response;
  }

  /// Runs the `onError` interceptor chain, then calls [onError] if the
  /// exception was not suppressed (i.e., no interceptor returned `null`).
  static Future<void> runOnError(
    EventFluxException exception,
    List<EventFluxInterceptor>? interceptors,
    Function(EventFluxException)? onError,
  ) async {
    if (interceptors != null && interceptors.isNotEmpty) {
      EventFluxException? error = exception;
      for (final interceptor in interceptors) {
        if (error == null) break;
        error = await interceptor.onError(error);
      }
      if (error != null) onError?.call(error);
    } else {
      onError?.call(exception);
    }
  }
}
