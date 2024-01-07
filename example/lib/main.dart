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
                      EventFlux.instance.connect(
                        EventFluxConnectionType.get,
                        url,
                        onSuccessCallback: (EventFluxResponse? data) {
                          if (data == null) {
                            return;
                          }
                          if (data.status == EventFluxStatus.connected) {
                            data.stream?.listen((event) {
                              log(event.data);
                            });
                          }
                        },
                        autoReconnect: true,
                        onError: (EventFluxException error) {
                          log('Error Message: ${error.message.toString()}');
                        },
                        onConnectionClose: () {
                          log('Connection Closed');
                        },
                      );
                    } catch (e) {
                      if (e is EventFluxException) {
                        log('Error Message: ${e.message.toString()}');
                      }
                    }
                  },
                  child: const Text("Connect")),
              TextButton(
                  onPressed: () async {
                    try {
                      EventFluxStatus status =
                          await EventFlux.instance.disconnect();
                      log('Status: $status');
                    } catch (e) {
                      if (e is EventFluxException) {
                        log('Error Message: ${e.message.toString()}');
                      }
                    }
                  },
                  child: const Text("Disconnect")),
            ],
          ),
        ),
      ),
    );
  }
}
