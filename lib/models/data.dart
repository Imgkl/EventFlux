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
    id = data.split("\n")[0].split('id:')[1];
    event = data.split("\n")[1].split('event:')[1];
    this.data = data.split("\n")[2].split('data:')[1];
  }
}
