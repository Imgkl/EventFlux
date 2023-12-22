/// Imports

import 'dart:async';
import 'dart:convert';

import 'package:eventflux/enum.dart';
import 'package:eventflux/models/base.dart';
import 'package:eventflux/models/data.dart';
import 'package:eventflux/models/exception.dart';
import 'package:eventflux/models/response.dart';
import 'package:eventflux/utils.dart';
import 'package:http/http.dart';

/// A class for managing event-driven data streams using Server-Sent Events (SSE).
///
/// It provides methods to connect, disconnect, and reconnect to an event stream.
/// This class follows the Singleton pattern to ensure only one instance exists.
class EventFlux extends EventFluxBase {
  EventFlux._();
  static EventFlux get instance => EventFlux._();
  static Client? _client;
  static StreamController<EventFluxData>? _streamController;

  /// Connects to a specified URL to start receiving event-driven data.
  ///
  /// [type] defines the HTTP method for the connection (GET or POST).
  /// [url] is the endpoint to connect to.
  /// [header] allows specifying HTTP headers. Defaults to accept text/event-stream.
  /// [onConnectionClose] is an optional callback executed when the connection is closed.
  /// [onError] is an optional callback executed when an error occurs.
  /// [body] is an optional.
  ///
  /// Returns an instance of EventFluxResponse containing the connection status and stream of data.
  @override
  EventFluxResponse connect(EventFluxConnectionType type, String url,
      {Map<String, String> header = const {'Accept': 'text/event-stream'},
      Function()? onConnectionClose,
      bool autoReconnect = false,
      Function(EventFluxException)? onError,
      Map<String, dynamic>? body}) {
    /// Initalise variables
    _client = Client();

    _streamController = StreamController<EventFluxData>.broadcast();

    RegExp lineRegex = RegExp(r'^([^:]*)(?::)?(?: )?(.*)?$');
    EventFluxData currentEventFluxData =
        EventFluxData(data: '', id: '', event: '');

    Request request = Request(
      type == EventFluxConnectionType.get ? 'GET' : 'POST',
      Uri.parse(url),
    );
    if (header.isNotEmpty) {
      request.headers.addAll(header);
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }
    eventFluxLog('Connection Initiated', LogEvent.info);

    try {
      Future<StreamedResponse> response = _client!.send(request);

      ///Listening to the response as a stream
      response.asStream().listen((data) {
        eventFluxLog('Connected', LogEvent.info);

        ///Applying transforms and listening to it
        data.stream
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .listen(
              (dataLine) {
                if (dataLine.isEmpty) {
                  /// When the data line is empty, it indicates that the complete event set has been read.
                  /// The event is then added to the stream.
                  _streamController!.add(currentEventFluxData);
                  currentEventFluxData =
                      EventFluxData(data: '', id: '', event: '');
                  return;
                }

                /// Parsing each line through the regex.
                Match match = lineRegex.firstMatch(dataLine)!;
                var field = match.group(1);
                if (field!.isEmpty) {
                  return;
                }
                var value = '';
                if (field == 'data') {
                  /// If the field is data, we get the data through the substring
                  value = dataLine.substring(
                    5,
                  );
                } else {
                  value = match.group(2) ?? '';
                }
                switch (field) {
                  case 'event':
                    currentEventFluxData.event = value;
                    break;
                  case 'data':
                    currentEventFluxData.data =
                        '${currentEventFluxData.data ?? ''}$value\n';
                    break;
                  case 'id':
                    currentEventFluxData.id = value;
                    break;
                  case 'retry':
                    break;
                }
              },
              cancelOnError: true,
              onDone: () {
                eventFluxLog('Stream Closed', LogEvent.info);

                /// When the stream is closed, onClose can be called to execute a function.
                if (onConnectionClose != null) onConnectionClose();
              },
              onError: (error, s) {
                if (autoReconnect) {
                  reconnect(
                    type,
                    url,
                    header: header,
                    body: body,
                    autoReconnect: autoReconnect,
                    onError: onError,
                    onConnectionClose: onConnectionClose,
                  );
                }
                if (error is! ClientException &&
                    (error as ClientException).message !=
                        'Connection closed while receiving data') {
                  eventFluxLog(
                      'Data Stream Listen Error: $error ', LogEvent.error);

                  /// Executes the onError function if it is not null
                  if (onError != null) {
                    onError(EventFluxException(message: error));
                  }

                  /// returns the error and the status
                  return EventFluxResponse(
                      status: EventFluxStatus.disconnected,
                      errorMessage: EventFluxException(message: error));
                }
              },
            );
      }, onError: (error, s) {
        if (autoReconnect) {
          reconnect(
            type,
            url,
            header: header,
            body: body,
            autoReconnect: autoReconnect,
            onError: onError,
            onConnectionClose: onConnectionClose,
          );
        }
        eventFluxLog('Stream Listen Error: $error', LogEvent.error);

        /// Executes the onError function if it is not null
        if (onError != null) onError(EventFluxException(message: error));

        /// returns the error and the status
        return EventFluxResponse(
            status: EventFluxStatus.disconnected,
            errorMessage: EventFluxException(message: error));
      });

      return EventFluxResponse(
          status: EventFluxStatus.connected, stream: _streamController!.stream);
    } catch (error) {
      if (autoReconnect) {
        reconnect(
          type,
          url,
          header: header,
          body: body,
          autoReconnect: autoReconnect,
          onError: onError,
          onConnectionClose: onConnectionClose,
        );
      }
      eventFluxLog('Client Initalise Error: $error', LogEvent.error);

      /// returns the error and the status
      return EventFluxResponse(
          status: EventFluxStatus.disconnected,
          errorMessage: EventFluxException(message: error));
    }
  }

  /// Disconnects from the event stream.
  ///
  /// Closes the HTTP client and the stream controller.
  /// Returns the disconnection status.
  @override
  EventFluxStatus disconnect() {
    eventFluxLog('Disconnecting', LogEvent.info);
    try {
      _client?.close();
      _streamController?.close();
      eventFluxLog('Disconnected', LogEvent.info);

      return EventFluxStatus.disconnected;
    } catch (error) {
      eventFluxLog('Disconnected', LogEvent.info);

      return EventFluxStatus.disconnected;
    }
  }

  /// Reconnects to the event stream.
  ///
  /// First, disconnects the current connection, then establishes a new connection.
  /// [type] and [url] specify the connection parameters.
  /// Returns the response from the new connection.
  @override
  EventFluxResponse reconnect(EventFluxConnectionType type, String url,
      {Map<String, String> header = const {'Accept': 'text/event-stream'},
      Function()? onConnectionClose,
      bool autoReconnect = false,
      Function(EventFluxException)? onError,
      Map<String, dynamic>? body}) {
    disconnect();
    return connect(type, url,
        header: header,
        onConnectionClose: onConnectionClose,
        autoReconnect: autoReconnect,
        onError: onError,
        body: body);
  }
}
