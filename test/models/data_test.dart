import 'package:eventflux/models/data.dart';
import 'package:test/test.dart';

void main() {
  group('EventFluxData', () {
    group('fromData', () {
      test('parses valid input correctly', () {
        final data =
            EventFluxData.fromData('id:123\nevent:message\ndata:Hello');
        expect(data.id, '123');
        expect(data.event, 'message');
        expect(data.data, 'Hello');
      });

      test('throws FormatException on too few lines', () {
        expect(
          () => EventFluxData.fromData('id:123\nevent:message'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException on single line', () {
        expect(
          () => EventFluxData.fromData('id:123'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException on empty string', () {
        expect(
          () => EventFluxData.fromData(''),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException when missing id: prefix', () {
        expect(
          () => EventFluxData.fromData('123\nevent:message\ndata:Hello'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException when missing event: prefix', () {
        expect(
          () => EventFluxData.fromData('id:123\nmessage\ndata:Hello'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException when missing data: prefix', () {
        expect(
          () => EventFluxData.fromData('id:123\nevent:message\nHello'),
          throwsA(isA<FormatException>()),
        );
      });

      test('handles empty values after prefixes', () {
        final data = EventFluxData.fromData('id:\nevent:\ndata:');
        expect(data.id, '');
        expect(data.event, '');
        expect(data.data, '');
      });

      test('handles extra lines beyond the first three', () {
        final data = EventFluxData.fromData(
            'id:1\nevent:msg\ndata:payload\nextra:ignored');
        expect(data.id, '1');
        expect(data.event, 'msg');
        expect(data.data, 'payload');
      });
    });
  });
}
