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
                    String url =
                        'https://api-dev.magnifi.com/realtime-portfolio/updates?authtoken=eyJraWQiOiJXRklUWnJIcmwzWGpEZXotVmc4TTRvSXNEUE1YN0ppbUtiN3JacVFyWEtjIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULl96UUxFS3NJR0NGMDFVNC1HRDNQZEVwNTBMQ1V2aWUzdkRKUkZpN19ub1Uub2FyMTZkaXJzcUVzWlIza2w2OTciLCJpc3MiOiJodHRwczovL2Rldi5hdXRoLm1hZ25pZmkuY29tL29hdXRoMi9kZWZhdWx0IiwiYXVkIjoiYXBpOi8vZGVmYXVsdCIsImlhdCI6MTcwMzIzMDc3NywiZXhwIjoxNzAzMzE3MTc3LCJjaWQiOiIwb2ExazR1eXYwNnR3bkFXODY5NyIsInVpZCI6IjAwdTFrNWJ5MGh4R1ZrcGZMNjk3Iiwic2NwIjpbIm9mZmxpbmVfYWNjZXNzIiwiZW1haWwiLCJwcm9maWxlIiwib3BlbmlkIl0sImF1dGhfdGltZSI6MTcwMzIzMDc3Nywic3ViIjoib29kMTBAYXBleC5jb20ifQ.jO5r6UtloA8wlZNODjNJ8KHB8RtkXyRUqMBe7nS1EPX7ihlPKPUtLJhlN-KJkXY3BUd3CYcoO_eiYlKKyv_Apd0OqtXxtmmO9FUeiE7NMtxzOtZuisgQ06D0NgyqOMXkb8DIfiInIpLgFYkPUyBeQcfx6CZmbfaSR7lTie93O00eYbN0yiYn3_gVyuwI86Nwyq0ziB0g2unLcttvoTbwd217pu_Chit5nR7dTOPpuP5fhk9FhEy8oFFs8tURClaaI9Ci3zjqdQ7graT4DRRorJ10FqAKIqzGMY2m2dcZ6aQHFf8fnA4jwvRXWSZAN7X-tTzmlNIO3E_7ZAy1jofW1g';
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
                          log('Recieved Event $event');
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
