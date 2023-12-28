
# Changelog 📝

### [v1.0.0] 🚀

#### Breaking
- Updated the `connect` method to be a void function instead of returning `EventFluxResponse`. This change accompanies the introduction of the `onSuccessCallback` parameter, which provides the `EventFluxResponse` via callback. This modification simplifies the connection process, making reconnections and stream updates more predictable and manageable.


### [v0.6.2] 🚀

#### Added
- Added support for `autoReconnect` on connect method.

### [v0.6.1] 🚀

#### Added
- Core functionality for connecting to server-sent event streams.
- `EventFlux` class to manage event stream connections.
- `EventFluxData` class for representing event data.
- `EventFluxException` class for handling exceptions.
- Support for both GET and POST connection types.
- Error and Disconnect handling and reconnection logic.