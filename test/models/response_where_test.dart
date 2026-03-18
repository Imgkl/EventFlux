import 'dart:async';

import 'package:eventflux/models/data.dart';
import 'package:eventflux/models/response.dart';
import 'package:eventflux/enum.dart';
import 'package:test/test.dart';

void main() {
  group('EventFluxResponse.where', () {
    test('filters events by type', () async {
      final controller = StreamController<EventFluxData>();
      final response = EventFluxResponse(
        status: EventFluxStatus.connected,
        stream: controller.stream,
      );

      final filtered = response.where('update');
      final results = <EventFluxData>[];
      filtered.listen(results.add);

      controller.add(EventFluxData(data: 'a', id: '1', event: 'update'));
      controller.add(EventFluxData(data: 'b', id: '2', event: 'message'));
      controller.add(EventFluxData(data: 'c', id: '3', event: 'update'));
      await controller.close();

      // Allow microtasks to flush
      await Future.delayed(Duration.zero);

      expect(results.length, 2);
      expect(results[0].data, 'a');
      expect(results[1].data, 'c');
    });

    test('returns empty stream when stream is null', () {
      final response = EventFluxResponse(
        status: EventFluxStatus.disconnected,
      );

      final filtered = response.where('update');
      expect(filtered, emitsDone);
    });

    test('returns empty stream when no events match', () async {
      final controller = StreamController<EventFluxData>();
      final response = EventFluxResponse(
        status: EventFluxStatus.connected,
        stream: controller.stream,
      );

      final filtered = response.where('nonexistent');
      final results = <EventFluxData>[];
      filtered.listen(results.add);

      controller.add(EventFluxData(data: 'a', id: '1', event: 'message'));
      await controller.close();

      await Future.delayed(Duration.zero);
      expect(results, isEmpty);
    });
  });
}
