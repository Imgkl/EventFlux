import 'package:eventflux/src/enum.dart';
import 'package:eventflux/src/models/data.dart';
import 'package:eventflux/src/models/exception.dart';

/// `EventFluxResponse` encapsulates the response from an EventFlux connection operation.
///
/// It contains the status of the connection, the data stream if the connection is successful,
/// and an error message in case of a failure.
///
/// Attributes:
///   - `status`: Represents the status of the EventFlux connection. It is of type `EventFluxStatus`
///     and indicates whether the connection is initiated, connected, or disconnected.
///   - `stream`: A stream of `EventFluxData` which provides the data received from the connection.
///     This is present only when the connection is successful (i.e., status is `connected`). It is
///     `null` if the connection is not established or if there's an error.
///   - `errorMessage`: Holds an `EventFluxException` instance that contains error details in case
///     the connection fails. This is `null` when the connection is successful.
///
/// Usage:
/// This class is typically used to return the result of an EventFlux connection operation,
/// allowing the caller to handle different connection states and data streaming appropriately.
class EventFluxResponse {
  final EventFluxStatus status;
  final Stream<EventFluxData>? stream;
  final EventFluxException? errorMessage;

  EventFluxResponse({required this.status, this.stream, this.errorMessage});
}
