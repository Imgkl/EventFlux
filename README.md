# EventFlux

EventFlux is a Dart package designed for efficient handling of server-sent event streams. It provides easy-to-use connectivity, data management, and robust error handling for real-time data applications.

## Features

- **Streamlined Connection Handling**: Easy setup for connecting to event streams with support for both GET and POST requests.
- **Real-Time Data Management**: Efficient processing and handling of real-time data streams.
- **Error Handling**: Robust mechanisms to manage connection interruptions and stream errors.
- **Singleton Client Management**: Ensures a single instance of the client throughout the application.
- **Customizable**: Extendable to fit various use cases and custom implementations.

## Installation

To use EventFlux in your Dart project, add it to your dependencies:

```yaml
dependencies:
  eventflux: ^0.6.2+1
```

## Usage

Here's a quick example to get you started:

```dart
import 'package:eventflux/eventflux.dart';

void main() {
  EventFlux eventFlux = EventFlux.instance;

  // Connect to an event stream
  EventFluxResponse response = eventFlux.connect(
    EventFluxConnectionType.get, 
    'https://example.com/events',
    autoReconnect: true
    onError:(e){
         // Log the error to Sentry or do something.
    }
    onConnectionClose: (){
        // do something.
    }
  );

  // Listen to the stream
  response.stream?.listen((data) {
    print('New event: ${data.event}, Data: ${data.data}');
  });
}

```

## Documentation
- **EventFlux**: Main class for managing event streams.
- **EventFluxData**: Data model for events received from the stream.
- **EventFluxException**: Custom exception handling for EventFlux operations.
- **EventFluxResponse**: Encapsulates the response from EventFlux operations.
- **Enums**: `EventFluxConnectionType` for specifying connection types and `EventFluxStatus` for connection status.

For detailed documentation, please see the respective Dart files in the `lib` folder.

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License