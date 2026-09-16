import 'package:eventflux/models/data.dart';
import 'package:test/test.dart';

void main() {
  group('EventFluxData.json', () {
    test('parses valid JSON object', () {
      final event = EventFluxData(
        data: '{"key":"value","number":42}',
        id: '1',
        event: 'message',
      );
      final result = event.json;
      expect(result, isA<Map>());
      expect(result['key'], 'value');
      expect(result['number'], 42);
    });

    test('parses valid JSON array', () {
      final event = EventFluxData(
        data: '[1,2,3]',
        id: '1',
        event: 'message',
      );
      final result = event.json;
      expect(result, isA<List>());
      expect(result, [1, 2, 3]);
    });

    test('parses valid JSON string', () {
      final event = EventFluxData(
        data: '"hello"',
        id: '1',
        event: 'message',
      );
      expect(event.json, 'hello');
    });

    test('throws FormatException on invalid JSON', () {
      final event = EventFluxData(
        data: 'not valid json',
        id: '1',
        event: 'message',
      );
      expect(() => event.json, throwsFormatException);
    });
  });
}
