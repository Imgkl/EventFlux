/// Represents exceptions specific to EventFlux operations.
///
/// `EventFluxException` is used to encapsulate errors that occur during
/// EventFlux connection and data handling processes. It implements Dart's
/// `Exception` interface, allowing it to be used in exception handling
/// structures.
///
/// The class contains a single field `message`, which holds information about
/// the error. This could be a simple string message or any object providing
/// more detailed information about the exception.
///
/// Attributes:
///   - `message`: An object that contains details about the exception. It can
///     be a string with a descriptive error message or a more complex object
///     providing additional information about the error condition.
///
/// Example:
/// ```dart
/// try {
///   // EventFlux operation that might throw an exception
/// } catch (e) {
///   if (e is EventFluxException) {
///     // Handle EventFlux-specific exceptions
///     print('EventFlux exception occurred: ${e.message}');
///   } else {
///     // Handle other exceptions
///   }
/// }
/// ```
///
/// This class allows for more specific exception handling for EventFlux-related
/// operations, making it easier to diagnose and respond to issues.
class EventFluxException implements Exception {
  final String? message;
  final int? statusCode;
  final String? reasonPhrase;

  EventFluxException({
    this.message,
    this.statusCode,
    this.reasonPhrase,
  });
}
