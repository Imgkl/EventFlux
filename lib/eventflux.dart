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
export 'src/client.dart';
export 'src/enum.dart';
export 'src/http_client_adapter.dart';
export 'src/models/data.dart';
export 'src/models/exception.dart';
export 'src/models/reconnect.dart';
export 'src/models/response.dart';
export 'src/models/web_config/web_config.dart';
