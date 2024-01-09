# EventFlux 🌐
<img src ="https://i.ibb.co/R4RcJVB/F.png"> 

EventFlux is a Dart package designed for efficient handling of server-sent event streams. It provides easy-to-use connectivity, data management, and robust error handling for real-time data applications. 🚀

## Inspiration 💡

EventFlux was born from the inspiration I found in the [`flutter_client_sse` package](https://pub.dev/packages/flutter_client_sse) by [Pratik Baid](https://github.com/pratikbaid3). His work laid a great foundation, and I aimed to build upon it, adding my own twist to enhance SSE stream management with better features. 🛠️

## Why EventFlux? 🌟

- **Streamlined Connection Handling**: Easy setup for connecting to event streams with support for both GET and POST requests. 🔌
- **Auto-Reconnect Capability**: Seamlessly maintains your connection, automatically reconnecting in case of any interruptions. 🔄
- **Real-Time Data Management**: Efficient processing and handling of real-time data streams. 📈
- **Error Handling**: Robust mechanisms to manage connection interruptions and stream errors. 🛡️
- **Singleton Client Management**: Ensures a single instance of the client throughout the application. 🌍
- **Customizable**: Extendable to fit various use cases and custom implementations. ✨

## Get Started in a Snap 📦

Add EventFlux to your Dart project's dependencies, and you're golden:

```yaml
dependencies:
  eventflux: 
```

## How to Use (Spoiler: It's Super Easy) 🔧

Here's a quick example to get you started:

```dart
import 'package:eventflux/eventflux.dart';

void main() {
  // Connect and start the magic!
   EventFlux.instance.connect(
     EventFluxConnectionType.get,
     'https://example.com/events',
     onSuccessCallback: (EventFluxResponse? response) {
      response.stream?.listen((data) {
        // Your data is now in the spotlight!
      });
     },
     onError: (oops) {
      // Oops! Time to handle those little hiccups.
    },
    autoReconnect: true // Keep the party going, automatically!
   );
}

```
## Need More Info? 📚
- **EventFlux**: Main class for managing event streams.
- **EventFluxData**: Data model for events received from the stream.
- **EventFluxException**: Custom exception handling for EventFlux operations.
- **EventFluxResponse**: Encapsulates the response from EventFlux operations.
- **Enums**: `EventFluxConnectionType` for specifying connection types and `EventFluxStatus` for connection status.

For detailed documentation, please see the respective Dart files in the `lib` folder.

### EventFlux Class Documentation 📖

`EventFlux` is a Dart class for managing server-sent event streams. It provides methods for connecting to, disconnecting from, and managing SSE streams.

### Method: connect

Connects to a server-sent event stream.

| Parameter          | Type                          | Description                                                   | Default                         |
|--------------------|-------------------------------|---------------------------------------------------------------|---------------------------------|
| `type`             | `EventFluxConnectionType`     | The type of HTTP request (GET or POST).                       | -                               |
| `url`              | `String`                      | The URL of the SSE stream to connect to.                      | -                               |
| `header`           | `Map<String, String>`         | HTTP headers for the request.                                 | `{'Accept': 'text/event-stream'}`|
| `onConnectionClose`| `Function()?`                 | Callback function triggered when the connection is closed.    | -                               |
| `autoReconnect`    | `bool`                        | Whether to automatically reconnect on disconnection.          | `false`                         |
| `onSuccessCallback`| `Function(EventFluxResponse?)`| Callback invoked upon successful connection.                  | -                               |
| `onError`          | `Function(EventFluxException)?`| Callback for handling errors.                                | -                               |
| `body`             | `Map<String, dynamic>?`       | Optional body for POST request types.                         | -                               |


### Method: disconnect

Disconnects from the SSE stream.

| Parameter   | Type              | Description                                      |
|-------------|-------------------|--------------------------------------------------|
| -           | -                 | This method has no parameters.                   |

Returns a `Future<EventFluxStatus>` indicating the disconnection status.


## Be a Part of the Adventure 🤝

Got ideas? Want to contribute? Jump aboard! Open an issue or send a pull request. Let's make EventFlux even more awesome together!

## The Boring (but Important) Stuff 📝

Licensed under MIT - use it freely, but let's play nice and give credit where it's due!
