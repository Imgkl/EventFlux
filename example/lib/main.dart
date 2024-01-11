import 'package:flutter/material.dart';

void main() {
  runApp(const EventFluxUsage());
}

class EventFluxUsage extends StatelessWidget {
  const EventFluxUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Refer Readme for usage"),
        ),
      ),
    );
  }
}
