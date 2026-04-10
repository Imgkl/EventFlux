import 'package:eventflux/models/exception.dart';
import 'package:test/test.dart';

void main() {
  group('EventFluxException', () {
    test('stores originalError and stackTrace', () {
      const originalError = FormatException('bad format');
      final stackTrace = StackTrace.current;

      final exception = EventFluxException(
        message: originalError.toString(),
        statusCode: 500,
        reasonPhrase: 'Internal Server Error',
        originalError: originalError,
        stackTrace: stackTrace,
      );

      expect(exception.message, contains('bad format'));
      expect(exception.statusCode, 500);
      expect(exception.reasonPhrase, 'Internal Server Error');
      expect(exception.originalError, same(originalError));
      expect(exception.stackTrace, same(stackTrace));
      expect(exception.originalError, isA<FormatException>());
    });

    test('preserves originalError and stackTrace from catch block', () {
      try {
        throw ArgumentError('bad argument');
      } on ArgumentError catch (e) {
        final exception = EventFluxException(
          message: e.toString(),
          originalError: e,
          stackTrace: e.stackTrace,
        );

        expect(exception.originalError, isA<ArgumentError>());
        expect(
          (exception.originalError as ArgumentError).message,
          'bad argument',
        );
        expect(exception.stackTrace, e.stackTrace);
      }
    });

    test('originalError and stackTrace are optional', () {
      final exception = EventFluxException(
        message: 'something went wrong',
        statusCode: 400,
        reasonPhrase: 'Bad Request',
      );

      expect(exception.message, 'something went wrong');
      expect(exception.statusCode, 400);
      expect(exception.reasonPhrase, 'Bad Request');
      expect(exception.originalError, isNull);
      expect(exception.stackTrace, isNull);
    });

    group('toString', () {
      test('includes statusCode, reasonPhrase, and message', () {
        final exception = EventFluxException(
          message: 'connection failed',
          statusCode: 503,
          reasonPhrase: 'Service Unavailable',
        );
        expect(
          exception.toString(),
          'EventFluxException [503 Service Unavailable]: connection failed',
        );
      });

      test('includes statusCode without reasonPhrase', () {
        final exception = EventFluxException(
          message: 'timeout',
          statusCode: 408,
        );
        expect(exception.toString(), 'EventFluxException [408]: timeout');
      });

      test('includes only message when no statusCode', () {
        final exception = EventFluxException(message: 'parse error');
        expect(exception.toString(), 'EventFluxException: parse error');
      });

      test('returns class name when all fields are null', () {
        final exception = EventFluxException();
        expect(exception.toString(), 'EventFluxException');
      });
    });
  });
}
