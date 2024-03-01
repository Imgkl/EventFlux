
# Changelog 📝

### v1.6.7 🛠️
- Updated Http package version to `1.2.1`


### v1.6.6
#### Breaking
- Disabled web support due to dependancy issue.
    - Refer [#5](https://github.com/Imgkl/EventFlux/issues/5) for more info.


### v1.6.0 🚀
#### Added
- Web support [#5](https://github.com/Imgkl/EventFlux/issues/5)
    - Your existing code now flawlessly extends its magic to the web – no extra setup required, just pure, uninterrupted functionality across platforms!

### v1.5.1 📝
#### Updated 
- Readme's `EventFlux for Every Scenario` Section

### v1.5.0 🚀
#### Added
- `spwan` method
    - Solves [#3](https://github.com/Imgkl/EventFlux/issues/3)
    - Provides users the flexibility to implement multiple SSE connections.
    - See the "Supercharged" section in the README for usage instructions.


### v1.0.1 🛠️
- Solves [#2](https://github.com/Imgkl/EventFlux/issues/2)
    - Retry doesn't use provided headers.   

### v1.0.0+2 🛠️
- If the connection is intentionaly severed/disconnected by calling `disconnet()` method, then the `autoReconnect` will not try to reconnect the connection again and again. 
    - I know, it's dumb mistake I made. Sorry. 🥹

### v1.0.0 🚀
#### Breaking
- Updated the `connect` method to be a void function instead of returning `EventFluxResponse`. This change accompanies the introduction of the `onSuccessCallback` parameter, which provides the `EventFluxResponse` via callback. This modification simplifies the connection process, making reconnections and stream updates more predictable and manageable.


### v0.6.2 🚀
#### Added
- support for `autoReconnect` on connect method.

### v0.6.1 🚀
#### Added
- Core functionality for connecting to server-sent event streams.
- `EventFlux` class to manage event stream connections.
- `EventFluxData` class for representing event data.
- `EventFluxException` class for handling exceptions.
- Support for both GET and POST connection types.
- Error and Disconnect handling and reconnection logic.

### v0.0.1 🍼
- `Hello world`
