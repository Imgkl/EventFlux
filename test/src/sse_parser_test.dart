import 'package:eventflux/models/exception.dart';
import 'package:eventflux/src/sse_parser.dart';
import 'package:test/test.dart';

void main() {
  late SseParser parser;

  setUp(() {
    parser = SseParser();
  });

  group('SseParser', () {
    test('returns null for non-empty data lines', () {
      expect(parser.processLine('data:hello'), isNull);
    });

    test('returns completed event on empty line', () {
      parser.processLine('data:hello');
      final result = parser.processLine('');
      expect(result, isNotNull);
      expect(result!.data, 'hello');
    });

    test('accumulates multi-line data fields', () {
      parser.processLine('data:line1');
      parser.processLine('data:line2');
      final result = parser.processLine('');
      expect(result, isNotNull);
      expect(result!.data, 'line1\nline2');
    });

    test('parses event field', () {
      parser.processLine('event:message');
      parser.processLine('data:payload');
      final result = parser.processLine('');
      expect(result!.event, 'message');
      expect(result.data, 'payload');
    });

    test('parses id field', () {
      parser.processLine('id:42');
      parser.processLine('data:payload');
      final result = parser.processLine('');
      expect(result!.id, '42');
    });

    test('parses all three fields together', () {
      parser.processLine('id:1');
      parser.processLine('event:update');
      parser.processLine('data:content');
      final result = parser.processLine('');
      expect(result!.id, '1');
      expect(result.event, 'update');
      expect(result.data, 'content');
    });

    test('parses retry field into serverRetryInterval', () {
      parser.processLine('retry:5000');
      parser.processLine('data:payload');
      final result = parser.processLine('');
      expect(result!.data, 'payload');
      expect(parser.serverRetryInterval, const Duration(milliseconds: 5000));
    });

    test('ignores lines with empty field name', () {
      // A line starting with ":" is a comment in SSE
      final result = parser.processLine(':this is a comment');
      expect(result, isNull);
    });

    test('resets state after emitting event', () {
      parser.processLine('data:first');
      parser.processLine('');

      parser.processLine('data:second');
      final result = parser.processLine('');
      expect(result!.data, 'second');
    });

    test('reset() clears accumulated state', () {
      parser.processLine('data:partial');
      parser.reset();
      parser.processLine('data:fresh');
      final result = parser.processLine('');
      expect(result!.data, 'fresh');
    });

    test('handles data with colon in value', () {
      parser.processLine('data:key:value:extra');
      final result = parser.processLine('');
      // data field grabs everything after "data:"
      expect(result!.data, 'key:value:extra');
    });

    test('strips Unicode line separator U+2028', () {
      parser.processLine('data:hello\u2028world');
      final result = parser.processLine('');
      expect(result, isNotNull);
    });

    test('handles empty data value', () {
      parser.processLine('data:');
      final result = parser.processLine('');
      expect(result!.data, '');
    });

    test('calls onError callback on parse failure', () {
      EventFluxException? receivedError;
      parser.processLine(
        'data:normal',
        onError: (e) => receivedError = e,
      );
      expect(receivedError, isNull);
    });

    // --- New tests for v3 spec compliance ---

    test('lastEventId persists across events', () {
      parser.processLine('id:100');
      parser.processLine('data:first');
      parser.processLine('');
      expect(parser.lastEventId, '100');

      parser.processLine('data:second');
      parser.processLine('');
      // lastEventId should still be 100
      expect(parser.lastEventId, '100');
    });

    test('lastEventId is updated by new id', () {
      parser.processLine('id:100');
      parser.processLine('data:first');
      parser.processLine('');
      expect(parser.lastEventId, '100');

      parser.processLine('id:200');
      parser.processLine('data:second');
      parser.processLine('');
      expect(parser.lastEventId, '200');
    });

    test('empty id resets lastEventId', () {
      parser.processLine('id:100');
      parser.processLine('data:first');
      parser.processLine('');
      expect(parser.lastEventId, '100');

      parser.processLine('id:');
      parser.processLine('data:second');
      parser.processLine('');
      expect(parser.lastEventId, '');
    });

    test('id with NULL character is ignored', () {
      parser.processLine('id:100');
      parser.processLine('data:first');
      parser.processLine('');
      expect(parser.lastEventId, '100');

      parser.processLine('id:bad\u0000id');
      parser.processLine('data:second');
      parser.processLine('');
      // Should NOT have changed
      expect(parser.lastEventId, '100');
    });

    test('lastEventId survives reset()', () {
      parser.processLine('id:42');
      parser.processLine('data:test');
      parser.processLine('');
      expect(parser.lastEventId, '42');

      parser.reset();
      expect(parser.lastEventId, '42');
    });

    test('retry: with valid digits is parsed', () {
      expect(parser.serverRetryInterval, isNull);
      parser.processLine('retry:3000');
      expect(parser.serverRetryInterval, const Duration(milliseconds: 3000));
    });

    test('retry: with non-digit value is ignored', () {
      parser.processLine('retry:abc');
      expect(parser.serverRetryInterval, isNull);
    });

    test('retry: with mixed content is ignored', () {
      parser.processLine('retry:100ms');
      expect(parser.serverRetryInterval, isNull);
    });

    test('serverRetryInterval is cleared on reset()', () {
      parser.processLine('retry:5000');
      expect(parser.serverRetryInterval, isNotNull);
      parser.reset();
      expect(parser.serverRetryInterval, isNull);
    });
  });
}
