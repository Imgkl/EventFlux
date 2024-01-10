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
- **Versatile Instance Creation**: Offers both singleton and multi-instance options for tailored SSE connections. 🌍
- **Customizable**: Extendable to fit various use cases and custom implementations. ✨

## EventFlux for Every Scenario 🌟

<img src="https://i.ibb.co/fQ1WpWX/flow-explanation.png" width="600"/>

## Get Started in a Snap 📦

Add EventFlux to your Dart project's dependencies, and you're golden:

```yaml
dependencies:
  eventflux: ^1.5.0
```


## How to Use (Spoiler: It's Super Easy) 🔧

Here's a quick example to get you started:

<details>
<summary>The Simple Streamer ✨</summary>
&nbsp;<br>
Need just one SSE connection? It's a breeze with EventFlux! Perfect for when your app is dancing solo with a single SSE.


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
&nbsp;<br>
</details>

<details>
<summary>Supercharged 🚀</summary>
&nbsp;<br>
When your app just need a multiple parallel SSE connections, use this.

```dart
import 'package:eventflux/eventflux.dart';

void main() {

  // Create separate EventFlux instances for each SSE connection
  EventFlux e1 = EventFlux.spawn();
  EventFlux e2 = EventFlux.spawn();

   // First connection - firing up!
  e1.connect(EventFluxConnectionType.get, 'url',
     onSuccessCallback: (EventFluxResponse? data) {
       data.stream?.listen((data) {
        // Your 1st Stream's data is being fetched!
      });
     },
     onError: (oops) {
      // Oops! Time to handle those little hiccups.
      },
  );

   // Second connection - firing up!
   e2.connect(EventFluxConnectionType.get, 'url',
     onSuccessCallback: (EventFluxResponse? data) {
       data.stream?.listen((data) {
        // Your 2nd Stream's data is also being fetched!
      });
     },
     onError: (oops) {
      // Oops! Time to handle those little hiccups.
      },
    autoReconnect: true // Keep the party going, automatically!
  );
}

```

ℹ️ Remember to disconnect all instances when you are done with it to avoid memory leaks.
&nbsp;<br>
</details>

## Need More Info? 📚

- **EventFlux**: Main class for managing event streams.
- **EventFluxData**: Data model for events received from the stream.
- **EventFluxException**: Custom exception handling for EventFlux operations.
- **EventFluxResponse**: Encapsulates the response from EventFlux operations.
- **Enums**: `EventFluxConnectionType` for specifying connection types and `EventFluxStatus` for connection status.

For detailed documentation, please see the respective Dart files in the `lib` folder.

### EventFlux Class Documentation 📖

`EventFlux` is a Dart class for managing server-sent event streams. It provides methods for connecting to, disconnecting from, and managing SSE streams.
<details>
<summary><b>connect</b></summary>
&nbsp;<br>
Connects to a server-sent event stream.

| Parameter           | Type                            | Description                                                | Default                           |
| ------------------- | ------------------------------- | ---------------------------------------------------------- | --------------------------------- |
| `type`              | `EventFluxConnectionType`       | The type of HTTP request (GET or POST).                    | -                                 |
| `url`               | `String`                        | The URL of the SSE stream to connect to.                   | -                                 |
| `header`            | `Map<String, String>`           | HTTP headers for the request.                              | `{'Accept': 'text/event-stream'}` |
| `onConnectionClose` | `Function()?`                   | Callback function triggered when the connection is closed. | -                                 |
| `autoReconnect`     | `bool`                          | Whether to automatically reconnect on disconnection.       | `false`                           |
| `onSuccessCallback` | `Function(EventFluxResponse?)`  | Callback invoked upon successful connection.               | -                                 |
| `onError`           | `Function(EventFluxException)?` | Callback for handling errors.                              | -                                 |
| `body`              | `Map<String, dynamic>?`         | Optional body for POST request types.                      | -                                 |
&nbsp;<br>
</details>

<details>
<summary><b>disconnect</b></summary>
&nbsp;<br>
Disconnects from the SSE stream.

| Parameter | Type | Description                    |
| --------- | ---- | ------------------------------ |
| -         | -    | This method has no parameters. |

Returns a `Future<EventFluxStatus>` indicating the disconnection status.
&nbsp;<br>
</details>

<details>
<summary><b>spawn</b></summary>
&nbsp;<br>

| Parameter | Type | Description                    |
| --------- | ---- | ------------------------------ |
| -         | -    | This method has no parameters. |

Returns a new instance of `EventFlux`, this is useful for having multiple SSE connections.
&nbsp;<br>
</details>

## Be a Part of the Adventure 🤝

Got ideas? Want to contribute? Jump aboard! Open an issue or send a pull request. Let's make EventFlux even more awesome together!

## The Boring (but Important) Stuff 📝

Licensed under MIT - use it freely, but let's play nice and give credit where it's due!
