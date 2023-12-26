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
                        'https://api-beta.magnifi.com//realtime-portfolio/updates?authtoken=eyJraWQiOiIwQlRCMUVna2pPcm9PXy15WEw3Wl9EeHFZeFYtUkhIWWVtTzh2di1jUUpJIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULnc4QWgxaS1Fc0pjQkhUTXAwRTV5NDZEQWdIQ01VRE9rZVZPREhlU19LMVEub2FyMTZiMTBrbGRwWHlZd2s2OTciLCJpc3MiOiJodHRwczovL2F1dGgubWFnbmlmaS5jb20vb2F1dGgyL2RlZmF1bHQiLCJhdWQiOiJhcGk6Ly9kZWZhdWx0IiwiaWF0IjoxNzAzNTc2Nzk1LCJleHAiOjE3MDM2NjMxOTUsImNpZCI6IjBvYTFtMXlsMXR4ejhaeXluNjk3IiwidWlkIjoiMDB1MXNmOHR4ajd1QVFoU0g2OTciLCJzY3AiOlsib2ZmbGluZV9hY2Nlc3MiLCJvcGVuaWQiLCJlbWFpbCIsInByb2ZpbGUiXSwiYXV0aF90aW1lIjoxNzAzMTY4Nzc1LCJzdWIiOiJ0b20uai52YW5ob3JuQGdtYWlsLmNvbSJ9.ERG_Aanvgblx6-y5bQQh1gTiSsKBnPcTVkKxdacyd6OjKoP_lJHdoS9LWW2DUlecZP7OordAJy163_6FKRxoBUspHG9k3JeYCZMJdr11E4jHTbhWjEu-EdyaAhf0cHg99i29fR6m61U5zagENbE3Du8NUbPiVmUeqq7RhZTlbPLVqSpGsbxCibj2TWDQDfAvQ8SbXGAj93RQWYNRfBXb96ukDaaOAsIVffYLnFtNXoaHXaD626t-qVY8uFOfjwbVHJ5kfr5lseu5uIBWzFW2-WTHDGsenzDKnp99zv61FbNNuUaSF0tvm_3p5sW8ZlryLMZufmlWIFpaBbcoeJYAIQ';
                    try {
                      EventFluxResponse response = EventFlux.instance.connect(
                        EventFluxConnectionType.get,
                        url,
                        autoReconnect: true,
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
                  onPressed: () async {
                    try {
                      EventFluxStatus status =
                          await EventFlux.instance.disconnect();
                      log('Status: $status');
                    } catch (e) {
                      if (e is EventFluxException) {
                        log('Error Message: ${e.message}');
                      }
                    }
                  },
                  child: const Text("Disconnect")),
              // TextButton(
              //     onPressed: () async {
              //       String url =
              //           'https://api-beta.magnifi.com//realtime-portfolio/updates?authtoken=eyJraWQiOiIwQlRCMUVna2pPcm9PXy15WEw3Wl9EeHFZeFYtUkhIWWVtTzh2di1jUUpJIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULnc4QWgxaS1Fc0pjQkhUTXAwRTV5NDZEQWdIQ01VRE9rZVZPREhlU19LMVEub2FyMTZiMTBrbGRwWHlZd2s2OTciLCJpc3MiOiJodHRwczovL2F1dGgubWFnbmlmaS5jb20vb2F1dGgyL2RlZmF1bHQiLCJhdWQiOiJhcGk6Ly9kZWZhdWx0IiwiaWF0IjoxNzAzNTc2Nzk1LCJleHAiOjE3MDM2NjMxOTUsImNpZCI6IjBvYTFtMXlsMXR4ejhaeXluNjk3IiwidWlkIjoiMDB1MXNmOHR4ajd1QVFoU0g2OTciLCJzY3AiOlsib2ZmbGluZV9hY2Nlc3MiLCJvcGVuaWQiLCJlbWFpbCIsInByb2ZpbGUiXSwiYXV0aF90aW1lIjoxNzAzMTY4Nzc1LCJzdWIiOiJ0b20uai52YW5ob3JuQGdtYWlsLmNvbSJ9.ERG_Aanvgblx6-y5bQQh1gTiSsKBnPcTVkKxdacyd6OjKoP_lJHdoS9LWW2DUlecZP7OordAJy163_6FKRxoBUspHG9k3JeYCZMJdr11E4jHTbhWjEu-EdyaAhf0cHg99i29fR6m61U5zagENbE3Du8NUbPiVmUeqq7RhZTlbPLVqSpGsbxCibj2TWDQDfAvQ8SbXGAj93RQWYNRfBXb96ukDaaOAsIVffYLnFtNXoaHXaD626t-qVY8uFOfjwbVHJ5kfr5lseu5uIBWzFW2-WTHDGsenzDKnp99zv61FbNNuUaSF0tvm_3p5sW8ZlryLMZufmlWIFpaBbcoeJYAIQ';
              //       try {
              //         EventFluxResponse response = await EventFlux.instance
              //             .reconnect(EventFluxConnectionType.get, url);
              //         if (response.status == EventFluxStatus.connected) {
              //           response.stream?.listen((event) {
              //             log('Event: ${event.data}');
              //           });
              //         } else {
              //           log('Error');
              //         }
              //       } catch (e) {
              //         if (e is EventFluxException) {
              //           log('Error Message: ${e.message}');
              //         }
              //       }
              //     },
              //     child: const Text("Reconnect")),
            ],
          ),
        ),
      ),
    );
  }
}
