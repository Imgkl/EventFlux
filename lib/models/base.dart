import 'package:eventflux/eventflux.dart';

/// Abstract base class for EventFlux connection management.
///
/// This class defines the core interface for managing connections in an
/// EventFlux implementation. It declares methods for connecting, disconnecting,
/// and reconnecting to an event stream.
///
/// Implementing classes are expected to provide concrete implementations for
/// these methods, adhering to the behavior and specifications outlined here.
///
/// Methods:
///   - `connect`: Establishes a connection to an event stream based on the given
///     parameters. This method must be implemented by subclasses to initiate
///     a connection using the specified connection type, URL, headers, and optional
///     body. It returns an `EventFluxResponse` which encapsulates the connection status
///     and potentially a stream of `EventFluxData`.
///     - Parameters:
///       - `type`: The `EventFluxConnectionType` (GET or POST) indicating the type
///         of HTTP connection.
///       - `url`: The URL of the event stream to connect to.
///       - `header`: Optional HTTP headers for the request. Defaults to accepting
///         'text/event-stream'.
///       - `body`: Optional body for POST requests.
///
///   - `disconnect`: Disconnects from the current event stream. This method
///     must be implemented by subclasses to properly close any open connections
///     and perform necessary cleanup. It returns an `EventFluxStatus` indicating
///     the result of the disconnection attempt.
///
///   - `reconnect`: Re-establishes a connection to an event stream. This method
///     should be implemented by subclasses to disconnect any existing connection
///     and then reconnect using the provided parameters. It returns an
///     `EventFluxResponse` similar to the `connect` method.
///     - Parameters:
///       - `type`: The `EventFluxConnectionType` (GET or POST) for the new connection.
///       - `url`: The URL to reconnect to.
///
/// Example Implementation:
/// ```dart
/// class MyEventFlux extends EventFluxBase {
///   @override
///   EventFluxResponse connect(...) {
///     // implementation
///   }
///
///   @override
///   EventFluxStatus disconnect() {
///     // implementation
///   }
///
///   @override
///   EventFluxResponse reconnect(...) {
///     // implementation
///   }
/// }
/// ```
///
/// This abstract class is central to ensuring a consistent interface for EventFlux
/// connection management across different implementations.
abstract class EventFluxBase {
  EventFluxResponse connect(EventFluxConnectionType type, String url,
      {Map<String, String> header = const {'Accept': 'text/event-stream'},
      Function()? onConnectionClose,
      Function(EventFluxException)? onError,
      Map<String, dynamic>? body});
  EventFluxStatus disconnect();
  EventFluxResponse reconnect(EventFluxConnectionType type, String url);
}
