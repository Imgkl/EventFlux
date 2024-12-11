<div align="center"><img src="https://i.ibb.co/tHK94xW/Untitled-2024-01-10-1728.png" width="200"/></div>

EventFlux is a Dart package designed for efficient handling of server-sent event streams. It provides easy-to-use connectivity, data management, and robust error handling for real-time data applications. 🚀


## Supported Platforms
| Android | iOS  |  Web | MacOS | Windows | Linux |
| ------ | ---- | ---- | ----- | ------- | ----- |
| ✅|✅|✅|✅|❓|❓| 

*Pssst... see those question marks? That's your cue, tech adventurers! Dive in, test, and tell me all about it.* 🚀🛠️



## Inspiration 💡

EventFlux was born from the inspiration I found in the [`flutter_client_sse` package](https://pub.dev/packages/flutter_client_sse) by [Pratik Baid](https://github.com/pratikbaid3). His work laid a great foundation, and I aimed to build upon it, adding my own twist to enhance SSE stream management with better features. 🛠️

## Why EventFlux? 🌟

- **Streamlined Connection Handling**: Easy setup for connecting to event streams with support for both GET and POST requests. 🔌
- **Auto-Reconnect Capability**: Seamlessly maintains your connection, automatically reconnecting in case of any server interruptions or network changes. Devs can choose to do linear or exponential backoff  🔄
- **Real-Time Data Management**: Efficient processing and handling of real-time data streams. 📈
- **Error Handling**: Robust mechanisms to manage connection interruptions and stream errors. 🛡️
- **Versatile Instance Creation**: Offers both singleton and factory patterns for tailored SSE connections. 🌍
- **Customizable**: Extendable to fit various use cases and custom implementations. ✨


## EventFlux for Every Scenario 🌟

<img src="https://i.ibb.co/gDWrnb0/flow.png" width="600"/>

## Get Started in a Snap 📦

Add EventFlux to your Dart project's dependencies, and you're golden:

```yaml
dependencies:
  eventflux: ^2.2.2-dev.2
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
     files: [
      /// Optional, If you want to send multipart files with the request
     ],
     multipartRequest: true, // Optional, By default, it will be considered as normal request, but if the files are provided or this flag is true, it will be considered as multipart request
     onSuccessCallback: (EventFluxResponse? response) {
      response.stream?.listen((data) {
        // Your data is now in the spotlight!
      });
     },
     onError: (oops) {
      // Oops! Time to handle those little hiccups.
      // You can also choose to disconnect here
    },
    autoReconnect: true // Keep the party going, automatically!
    reconnectConfig: ReconnectConfig(
        mode: ReconnectMode.linear, // or exponential,
        interval: Duration(seconds: 5),
        reconnectHeader: () async {
          /// If you want to send custom headers during reconnect which are different from the initial connection
          /// If you don't want to send any headers, you can skip this, initial headers will be used 

          // Your async code to refresh or fetch headers
          // For example, fetching a new access token:
          String newAccessToken = await fetchNewAccessToken();
          return {
            'Authorization': 'Bearer $newAccessToken',
            'Accept': 'text/event-stream',
          };
        },
        maxAttempts: 5, // or -1 for infinite,
        onReconnect: () {
          // Things to execute when reconnect happens
          // FYI: for network changes, the `onReconnect` will not be called. 
          // It will only be called when the connection is interupted by the server and eventflux is trying to reconnect.
        }
    ),
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
  e1.connect(EventFluxConnectionType.get, 
     'https://example1.com/events',
     tag: "SSE Connection 1", // Optional tag for debugging, you'll see this in logs
     onSuccessCallback: (EventFluxResponse? data) {
       data.stream?.listen((data) {
        // Your 1st Stream's data is being fetched!
      });
     },
     onError: (oops) {
        // Oops! Time to handle those little hiccups.
        // You can also choose to disconnect here
      },
  );

   // Second connection - firing up!
   e2.connect(EventFluxConnectionType.get,
     'https://example2.com/events',
     tag: "SSE Connection 2", // Optional tag for debugging, you'll see this in logs
     onSuccessCallback: (EventFluxResponse? data) {
       data.stream?.listen((data) {
        // Your 2nd Stream's data is also being fetched!
      });
     },
     onError: (oops) {
        // Oops! Time to handle those little hiccups.
        // You can also choose to disconnect here
      },
    autoReconnect: true // Keep the party going, automatically!
    reconnectConfig: ReconnectConfig(
        mode: ReconnectMode.exponential, // or linear,
        interval: Duration(seconds: 5),
        maxAttempts: 5, // or -1 for infinite,
        reconnectHeader: () async {
          /// If you want to send custom headers during reconnect which are different from the initial connection
          /// If you don't want to send any headers, you can skip this, initial headers will be used 

          // Your async code to refresh or fetch headers
          // For example, fetching a new access token:
          String newAccessToken = await fetchNewAccessToken();
          return {
            'Authorization': 'Bearer $newAccessToken',
            'Accept': 'text/event-stream',
          };
        },
        onReconnect: () {
          // Things to execute when reconnect happens
          // FYI: for network changes, the `onReconnect` will not be called. 
          // It will only be called when the connection is interupted by the server and eventflux is trying to re-establish the connection.
        }
    ),
  );
}

```

ℹ️ Remember to disconnect all instances when you are done with it to avoid memory leaks.
&nbsp;<br>

</details>

## Need More Info? 📚

- **EventFlux**: Main class for managing event streams.
- **ReconnectConfig**: Configuration for auto-reconnect.
- **EventFluxData**: Data model for events received from the stream.
- **EventFluxException**: Custom exception handling for EventFlux operations.
- **EventFluxResponse**: Encapsulates the response from EventFlux operations.
- **Enums**: `EventFluxConnectionType` for specifying connection types and `EventFluxStatus` for connection status.

For detailed documentation, please see the respective Dart files in the `lib` folder.

### EventFlux Class Documentation 📖

`EventFlux` is a Dart class for managing server-sent event streams. It provides methods for connecting to, disconnecting from, and managing SSE streams.
<details>
<summary><b>Connect</b></summary>
&nbsp;<br>
Connects to a server-sent event stream.

| Parameter           | Type                            | Description                                                | Default                           |
| ------------------- | ------------------------------- | ---------------------------------------------------------- | --------------------------------- |
| `type`              | `EventFluxConnectionType`       | The type of HTTP request (GET or POST).                    | -                                 |
| `url`               | `String`                        | The URL of the SSE stream to connect to.                   | -                                 |
| `header`            | `Map<String, String>`           | HTTP headers for the request.                              | `{'Accept': 'text/event-stream'}` |
| `onConnectionClose` | `Function()?`                   | Callback function triggered when the connection is closed. | -                                 |
| `autoReconnect`     | `bool`                          | Whether to automatically reconnect on disconnection.       | `false`                           |
| `reconnectConfig`   | `ReconnectConfig?`              | Configuration for auto-reconnect. If `auto-reconnect` is true, this is required| -                                 |
| `onSuccessCallback` | `Function(EventFluxResponse?)`  | Callback invoked upon successful connection.               | -                                 |
| `onError`           | `Function(EventFluxException)?` | Callback for handling errors.                              | -                                 |
| `body`              | `Map<String, dynamic>?`         | Optional body for POST request types.                      | -                                 |
| `files`             | `List<File>?`                   | Optional list of files to send with the request.           | -                                 |
| `multipartRequest`  | `bool`                          | Whether the request is a multipart request.                | `false`                           |
| `tag`               | `String`                        | Optional tag for debugging.                                | -                                 |
| `logReceivedData`  | `bool`                          | Whether to log received data.                              | `false`                           |
| `httpClient`        | `HttpClientAdapter?`            | Optional Http Client Adapter to allow usage of different http clients. | -                                 |
| `webConfig`         | `WebConfig?`                    | Allows configuring the web client. Ignored for non-web platforms. | -                                 |

&nbsp;<br>
</details>

<details>
<summary><b>Disconnect</b></summary>
&nbsp;<br>
Disconnects from the SSE stream.

| Parameter | Type | Description                    |
| --------- | ---- | ------------------------------ |
| -         | -    | This method has no parameters. |

Returns a `Future<EventFluxStatus>` indicating the disconnection status.
&nbsp;<br>
</details>

<details>
<summary><b>Spawn</b></summary>
&nbsp;<br>

| Parameter | Type | Description                    |
| --------- | ---- | ------------------------------ |
| -         | -    | This method has no parameters. |

Returns a new instance of `EventFlux`, this is used for having multiple SSE connections.
&nbsp;<br>
</details>

## Be a Part of the Adventure 🤝

Got ideas? Want to contribute? Jump aboard! Open an issue or send a pull request. Let's make EventFlux even more awesome together!

## The Boring (but Important) Stuff 📝

Licensed under MIT - use it freely, but let's play nice and give credit where it's due!
