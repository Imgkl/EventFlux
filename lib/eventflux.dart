library eventflux;

/// EventFlux Library Exports.
///
/// This file consolidates and exports the essential components of the EventFlux library,
/// making it easier to import them into other Dart files. By including this single file,
/// you gain access to all the primary classes and enums required to work with EventFlux.
///
/// Exports:
///   - `client.dart`: Contains the implementation of the EventFlux client. This is
///     responsible for managing the connection to the event source.
///   - `enum.dart`: Defines enums used across the EventFlux library, such as
///     `EventFluxConnectionType` and `EventFluxStatus`.
///   - `eventflux.dart`: Provides the main EventFlux class, which is the central point of
///     interaction with the EventFlux functionality.
///   - `models/base.dart`: Includes the base classes that are extended by other components
///     within the library, such as `EventFluxBase`.
///   - `models/data.dart`: Defines the `EventFluxData` model, which represents the data
///     structure for events handled by EventFlux.
///   - `models/exception.dart`: Contains the `EventFluxException` class, used to represent
///     exceptions specific to EventFlux operations.
///   - `models/response.dart`: Provides the `EventFluxResponse` class, encapsulating the
///     response from EventFlux operations, including connection status and data streams.
///
/// Usage:
/// Import this file into your Dart code to access all the primary features of the EventFlux
/// library with a single import statement.
///
/// Example:
/// ```dart
/// import 'package:eventflux/eventflux_exports.dart';
///
/// ```
///
/// This export file simplifies the usage of the EventFlux library and promotes a clean
/// and organized way of accessing its components.
export 'client.dart';
export 'enum.dart';
export 'eventflux.dart';
export 'models/base.dart';
export 'models/data.dart';
export 'models/exception.dart';
export 'models/response.dart';
