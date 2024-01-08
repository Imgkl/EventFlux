
# Changelog 📝

### [v1.0.1]
- Fixes issue [#2](https://github.com/Imgkl/EventFlux/issues/2)
    - Retry doesn't use provided headers.   

### [v1.0.0+2]
- If the connection is intentionaly severed/disconnected by calling `disconnet()` method, then the `autoReconnect` will not try to reconnect the connection again and again. 
    - I know, it's dumb mistake I made. Sorry. 🥹

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
