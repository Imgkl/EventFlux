import 'package:eventflux/enum.dart';
import 'package:eventflux/http_client_adapter.dart';
import 'package:eventflux/models/exception.dart';
import 'package:eventflux/models/interceptor.dart';
import 'package:eventflux/models/reconnect.dart';
import 'package:eventflux/models/response.dart';
import 'package:eventflux/models/web_config/web_config.dart';
import 'package:http/http.dart';

/// Immutable data class bundling all [EventFlux.connect] parameters.
///
/// Eliminates the 15-parameter signatures on `_start` and
/// `_attemptReconnectIfNeeded` by passing a single config object.
class ConnectionConfig {
  final EventFluxConnectionType type;
  final String url;
  final Map<String, String> header;
  final bool autoReconnect;
  final ReconnectConfig? reconnectConfig;
  final Function(EventFluxResponse?) onSuccessCallback;
  final Function(EventFluxException)? onError;
  final Function()? onConnectionClose;
  final HttpClientAdapter? httpClient;
  final Map<String, dynamic>? body;
  final String? tag;
  final bool logReceivedData;
  final List<MultipartFile>? files;
  final bool multipartRequest;
  final WebConfig? webConfig;
  final List<EventFluxInterceptor>? interceptors;
  final Future<void>? abortTrigger;

  const ConnectionConfig({
    required this.type,
    required this.url,
    required this.onSuccessCallback,
    this.header = const {'Accept': 'text/event-stream', 'Cache-Control': 'no-store'},
    this.autoReconnect = false,
    this.reconnectConfig,
    this.onError,
    this.onConnectionClose,
    this.httpClient,
    this.body,
    this.tag,
    this.logReceivedData = false,
    this.files,
    this.multipartRequest = false,
    this.webConfig,
    this.interceptors,
    this.abortTrigger,
  });

  /// Returns a copy with updated headers — used for reconnect header refresh.
  ConnectionConfig copyWithHeader(Map<String, String> newHeader) {
    return ConnectionConfig(
      type: type,
      url: url,
      onSuccessCallback: onSuccessCallback,
      header: newHeader,
      autoReconnect: autoReconnect,
      reconnectConfig: reconnectConfig,
      onError: onError,
      onConnectionClose: onConnectionClose,
      httpClient: httpClient,
      body: body,
      tag: tag,
      logReceivedData: logReceivedData,
      files: files,
      multipartRequest: multipartRequest,
      webConfig: webConfig,
      interceptors: interceptors,
      abortTrigger: abortTrigger,
    );
  }
}
