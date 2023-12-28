/// Enum representing the various statuses of an EventFlux connection.
///
/// - `connectionInitiated`: Indicates that the connection process has started.
/// - `connected`: Represents a successful connection to the event stream.
/// - `disconnected`: Signifies that the connection has been closed or lost.
/// - `error`: Indicates that an error has occurred during the connection/disconnection process.
enum EventFluxStatus {
  connectionInitiated,
  connected,
  disconnected,
  error,
}

/// Enum to define the type of HTTP connection to be used in EventFlux.
///
/// - `get`: Use an HTTP GET request for the connection. This is typically used
///   for retrieving data from a server without modifying any server-side state.
/// - `post`: Use an HTTP POST request. This is commonly used for submitting data
///   to be processed to a server, which may result in a change in server-side state
///   or data being stored.
enum EventFluxConnectionType { get, post }
