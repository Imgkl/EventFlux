import 'package:eventflux/models/exception.dart';
import 'package:http/http.dart';

/// Abstract class for intercepting EventFlux request/response lifecycle.
///
/// Subclass this to hook into requests before sending, responses after
/// receiving, and errors when they occur. All methods have pass-through
/// defaults so you only override what you need.
///
/// Example:
/// ```dart
/// class AuthInterceptor extends EventFluxInterceptor {
///   @override
///   Future<BaseRequest> onRequest(BaseRequest request) async {
///     request.headers['Authorization'] = 'Bearer $token';
///     return request;
///   }
/// }
/// ```
abstract class EventFluxInterceptor {
  /// Called before a request is sent.
  ///
  /// Modify the [request] (e.g., add headers, log) and return it.
  /// Throw [EventFluxException] to short-circuit — the request won't
  /// be sent and the error chain will run instead.
  Future<BaseRequest> onRequest(BaseRequest request) async => request;

  /// Called after a response is received, before status-code branching.
  ///
  /// Inspect the [response] (status code, headers). Must NOT consume
  /// the stream body.
  Future<StreamedResponse> onResponse(StreamedResponse response) async =>
      response;

  /// Called when an error occurs.
  ///
  /// Return the [exception] to propagate it, or return `null` to suppress
  /// it (the user's `onError` callback won't fire, but reconnection still
  /// proceeds independently).
  Future<EventFluxException?> onError(EventFluxException exception) async =>
      exception;
}
