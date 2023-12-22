import 'dart:developer';

import 'package:eventflux/eventflux.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () {
                    String url = 'https://example.com/events';
                    try {
                      EventFluxResponse response = EventFlux.instance.connect(
                        EventFluxConnectionType.get,
                        url,
                        onError: (error) {
                          log('Error Message Logged from UI: ${error.message}');
                        },
                        onConnectionClose: () {
                          log('Connection Closed');
                        },
                      );
                      if (response.status == EventFluxStatus.connected) {
                        response.stream?.listen((event) {
                          log('Received Event');
                        });
                      } else {
                        log('Error');
                      }
                    } catch (e) {
                      if (e is EventFluxException) {
                        log('Error Message: ${e.message}');
                      }
                    }
                  },
                  child: const Text("Connect")),
              TextButton(
                  onPressed: () {
                    try {
                      EventFluxStatus status = EventFlux.instance.disconnect();
                      log('Status: $status');
                    } catch (e) {
                      if (e is EventFluxException) {
                        log('Error Message: ${e.message}');
                      }
                    }
                  },
                  child: const Text("Disconnect")),
              TextButton(
                  onPressed: () {
                    String url = 'https://example.com/events';
                    try {
                      EventFluxResponse response = EventFlux.instance
                          .reconnect(EventFluxConnectionType.get, url);
                      if (response.status == EventFluxStatus.connected) {
                        response.stream?.listen((event) {
                          log('Event: ${event.data}');
                        });
                      } else {
                        log('Error');
                      }
                    } catch (e) {
                      if (e is EventFluxException) {
                        log('Error Message: ${e.message}');
                      }
                    }
                  },
                  child: const Text("Reconnect")),
            ],
          ),
        ),
      ),
    );
  }
}
