@TestOn('vm')
import 'dart:async';

import 'package:eventflux/eventflux.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

/// Run this with `flutter test test/integration/eventflux_test_vm.dart`
void main() {
  late EventFlux eventFlux;

  setUp(() {
    eventFlux = EventFlux.spawn();
  });

  for (final connectionType in [
    EventFluxConnectionType.get,
    EventFluxConnectionType.post,
  ]) {
    test(
      'uses Client in non-browser environment for $connectionType',
      () {
        final events = <String>[];
        final completer = Completer<void>();
        const testUrl = 'https://localhost:4567';

        fakeAsync((async) {
          eventFlux.connect(
            connectionType,
            testUrl,
            onSuccessCallback: (response) {
              response?.stream?.listen(
                (event) {
                  events.add(event.data);
                  if (events.length >= 3) {
                    completer.complete();
                  }
                },
                onError: (error) => completer.completeError(error),
              );
            },
            onError: (error) => completer.completeError(error),
          );
        });

        expect(eventFlux.client, isA<Client>());
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  }
}
