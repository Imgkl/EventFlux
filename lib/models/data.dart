import 'dart:convert';

/// Represents the data structure for an EventFlux event.
///
/// `EventFluxData` is used to store and represent the data associated with
/// a specific event in the EventFlux system. It encapsulates details such as
/// the event's ID, name, and the actual data payload.
///
/// Attributes:
///   - `id`: A nullable string representing the unique identifier of the event.
///     This is typically used to distinguish between different events.
///   - `event`: A nullable string indicating the name or type of the event.
///     This is used to categorize or identify the nature of the event.
///   - `data`: A nullable string containing the actual payload or information
///     associated with the event.
///
/// Constructors:
///   - `EventFluxData`: The default constructor requires all three attributes
///     (`data`, `id`, `event`) to be provided explicitly.
///   - `EventFluxData.fromData`: A named constructor that creates an instance
///     from a single string, expecting the string to be formatted with each
///     attribute on a new line, prefixed with its name and a colon.
///
/// Example:
/// ```dart
/// EventFluxData event = EventFluxData(id: '123', event: 'message', data: 'Hello, World!');
/// EventFluxData eventFromData = EventFluxData.fromData('id:123\nevent:message\ndata:Hello, World!');
/// ```
///
/// This class provides a structured way to handle and pass around event data
/// within the EventFlux system, ensuring consistency and ease of access to
/// different parts of an event's information.
class EventFluxData {
  /// Event ID
  String id = '';

  /// Event Name
  String event = '';

  /// Event Data
  String data = '';

  /// Constructs an instance of `EventFluxData` with given id, event, and data.
  EventFluxData({required this.data, required this.id, required this.event});
  EventFluxData.fromData(String data) {
    final lines = data.split("\n");
    if (lines.length < 3) {
      throw FormatException(
        'EventFluxData.fromData expects at least 3 lines (id:, event:, data:), '
        'got ${lines.length}',
        data,
      );
    }
    final idIdx = lines[0].indexOf('id:');
    final eventIdx = lines[1].indexOf('event:');
    final dataIdx = lines[2].indexOf('data:');
    if (idIdx == -1 || eventIdx == -1 || dataIdx == -1) {
      throw FormatException(
        'EventFluxData.fromData expects lines prefixed with "id:", "event:", "data:"',
        data,
      );
    }
    id = lines[0].substring(idIdx + 3);
    event = lines[1].substring(eventIdx + 6);
    this.data = lines[2].substring(dataIdx + 5);
  }

  /// Parses the [data] field as JSON and returns the decoded result.
  dynamic get json => jsonDecode(data);
}
