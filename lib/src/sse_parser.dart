import 'package:eventflux/models/data.dart';
import 'package:eventflux/models/exception.dart';
import 'package:eventflux/utils.dart';

/// Stateful SSE line parser.
///
/// Processes individual lines from the UTF-8 / LineSplitter pipeline and
/// returns a complete [EventFluxData] when an empty line is encountered
/// (per the SSE spec). Returns `null` for non-terminal lines.
class SseParser {
  static final RegExp _lineRegex = RegExp(r'^([^:]*)(?::)?(?: )?(.*)?$');
  static final RegExp _retryRegex = RegExp(r'^\d+$');
  static final RegExp _unicodeSeparatorRegex = RegExp('[\u2028\u2029]');

  EventFluxData _current = EventFluxData(data: '', id: '', event: '');
  final StringBuffer _dataBuffer = StringBuffer();

  /// Last event ID — persists across reconnections per WHATWG spec.
  String _lastEventId = '';
  String get lastEventId => _lastEventId;

  /// Server-requested retry interval from `retry:` field.
  Duration? _serverRetryInterval;
  Duration? get serverRetryInterval => _serverRetryInterval;

  /// Processes a single SSE line.
  ///
  /// Returns a completed [EventFluxData] on an empty line (event boundary),
  /// or `null` when the line is accumulated into the current event.
  ///
  /// When [logReceivedData] is true the completed event data is logged.
  /// Parse errors are reported via [onError] if provided.
  EventFluxData? processLine(
    String dataLine, {
    String? tag,
    bool logReceivedData = false,
    Function(EventFluxException)? onError,
  }) {
    if (dataLine.isEmpty) {
      final completed = _current;
      // Extract accumulated data, stripping trailing '\n' (per SSE spec)
      var accumulated = _dataBuffer.toString();
      if (accumulated.endsWith('\n')) {
        accumulated = accumulated.substring(0, accumulated.length - 1);
      }
      completed.data = accumulated;
      _dataBuffer.clear();
      if (logReceivedData) {
        eventFluxLog(completed.data, LogEvent.info, tag);
      }
      _current = EventFluxData(data: '', id: '', event: '');
      return completed;
    }

    try {
      // Remove the Unicode line separator that breaks the regex parse.
      final sanitizedDataLine = dataLine.replaceAll(_unicodeSeparatorRegex, '');

      final match = _lineRegex.firstMatch(sanitizedDataLine);
      if (match == null) return null;

      var field = match.group(1);
      if (field!.isEmpty) return null;

      var value = match.group(2) ?? '';

      switch (field) {
        case 'event':
          _current.event = value;
          break;
        case 'data':
          _dataBuffer.write(value);
          _dataBuffer.writeCharCode(0x0A);
          break;
        case 'id':
          // Per WHATWG spec: ignore if value contains NULL character
          if (!value.contains('\u0000')) {
            _current.id = value;
            _lastEventId = value;
          }
          break;
        case 'retry':
          if (_retryRegex.hasMatch(value)) {
            _serverRetryInterval = Duration(milliseconds: int.parse(value));
          }
          break;
      }
    } catch (e) {
      eventFluxLog('Error parsing data line: $e', LogEvent.error, tag);
      onError?.call(
        EventFluxException(
          message: 'Error parsing data line: $e',
          originalError: e,
          stackTrace: e is Error ? e.stackTrace : null,
        ),
      );
    }

    return null;
  }

  /// Resets the accumulated state for a new connection.
  ///
  /// Per WHATWG spec, [_lastEventId] persists across reconnections.
  /// [_serverRetryInterval] is cleared (per-connection).
  void reset() {
    _current = EventFluxData(data: '', id: '', event: '');
    _dataBuffer.clear();
    _serverRetryInterval = null;
  }

  /// Full reset including [_lastEventId].
  ///
  /// Called on explicit disconnect to prevent stale IDs from leaking
  /// into a subsequent connection.
  void fullReset() {
    reset();
    _lastEventId = '';
  }
}
