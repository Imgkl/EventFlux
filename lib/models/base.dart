import 'package:eventflux/eventflux.dart';
import 'package:http/http.dart';

/// Abstract base class for EventFlux connection management.
///
/// This class defines the core interface for managing connections in an
/// EventFlux implementation. It declares methods for connecting, disconnecting,
/// and reconnecting to an event stream.
///
/// Implementing classes are expected to provide concrete implementations for
/// these methods, adhering to the behavior and specifications outlined here.
abstract class EventFluxBase {
  void connect(
    EventFluxConnectionType type,
    String url, {
    required Function(EventFluxResponse?) onSuccessCallback,
    Map<String, String> header = const {'Accept': 'text/event-stream', 'Cache-Control': 'no-store'},
    Function()? onConnectionClose,
    bool autoReconnect = false,
    ReconnectConfig? reconnectConfig,
    Function(EventFluxException)? onError,
    HttpClientAdapter? httpClient,
    Map<String, dynamic>? body,
    String? tag,
    bool logReceivedData = false,
    List<MultipartFile>? files,
    bool multipartRequest = false,
    WebConfig? webConfig,
    List<EventFluxInterceptor>? interceptors,
    Future<void>? abortTrigger,
  });
  Future<EventFluxStatus> disconnect();
}
