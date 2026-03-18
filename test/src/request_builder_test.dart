import 'dart:convert';

import 'package:eventflux/enum.dart';
import 'package:eventflux/src/connection_config.dart';
import 'package:eventflux/src/request_builder.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('RequestBuilder', () {
    group('standard request', () {
      test('builds GET request with correct method and URL', () {
        final config = ConnectionConfig(
          type: EventFluxConnectionType.get,
          url: 'http://example.com/sse',
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config);
        expect(request, isA<Request>());
        expect(request.method, 'GET');
        expect(request.url, Uri.parse('http://example.com/sse'));
      });

      test('builds POST request with correct method', () {
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config);
        expect(request, isA<Request>());
        expect(request.method, 'POST');
      });

      test('adds headers to standard request', () {
        final headers = {'Authorization': 'Bearer token', 'Accept': 'text/event-stream'};
        final config = ConnectionConfig(
          type: EventFluxConnectionType.get,
          url: 'http://example.com/sse',
          header: headers,
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config) as Request;
        expect(request.headers['Authorization'], 'Bearer token');
        expect(request.headers['Accept'], 'text/event-stream');
      });

      test('adds JSON-encoded body to standard request', () {
        final body = {'key': 'value', 'number': 42};
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          body: body,
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config) as Request;
        expect(request.body, jsonEncode(body));
      });

      test('standard request with no body has empty body', () {
        final config = ConnectionConfig(
          type: EventFluxConnectionType.get,
          url: 'http://example.com/sse',
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config) as Request;
        expect(request.body, isEmpty);
      });
    });

    group('multipart request', () {
      test('builds MultipartRequest when multipartRequest is true', () {
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          multipartRequest: true,
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config);
        expect(request, isA<MultipartRequest>());
      });

      test('builds MultipartRequest when files are provided', () {
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          files: [MultipartFile.fromString('file', 'content')],
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config);
        expect(request, isA<MultipartRequest>());
      });

      test('adds headers to multipart request', () {
        final headers = {'Authorization': 'Bearer token'};
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          header: headers,
          multipartRequest: true,
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config) as MultipartRequest;
        expect(request.headers['Authorization'], 'Bearer token');
      });

      test('adds body fields to multipart request', () {
        final body = {'key': 'value'};
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          body: body,
          multipartRequest: true,
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config) as MultipartRequest;
        expect(request.fields, body);
      });

      test('adds files to multipart request', () {
        final file = MultipartFile.fromString('test', 'content');
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          multipartRequest: true,
          files: [file],
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config) as MultipartRequest;
        expect(request.files.single, file);
      });

      test('adds files and fields together', () {
        final file = MultipartFile.fromString('file', 'content');
        final body = {'key': 'value'};
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          multipartRequest: true,
          files: [file],
          body: body,
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config) as MultipartRequest;
        expect(request.files.single, file);
        expect(request.fields, body);
      });
    });

    group('abort support', () {
      test('builds AbortableRequest when abortTrigger is provided', () {
        final trigger = Future<void>.value();
        final config = ConnectionConfig(
          type: EventFluxConnectionType.get,
          url: 'http://example.com/sse',
          onSuccessCallback: (_) {},
          abortTrigger: trigger,
        );

        final request = RequestBuilder.build(config);
        expect(request, isA<AbortableRequest>());
        expect((request as AbortableRequest).abortTrigger, trigger);
      });

      test('builds standard Request when abortTrigger is null', () {
        final config = ConnectionConfig(
          type: EventFluxConnectionType.get,
          url: 'http://example.com/sse',
          onSuccessCallback: (_) {},
        );

        final request = RequestBuilder.build(config);
        expect(request, isA<Request>());
        expect(request, isNot(isA<AbortableRequest>()));
      });

      test('builds AbortableMultipartRequest when trigger + multipart', () {
        final trigger = Future<void>.value();
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          onSuccessCallback: (_) {},
          multipartRequest: true,
          abortTrigger: trigger,
        );

        final request = RequestBuilder.build(config);
        expect(request, isA<AbortableMultipartRequest>());
        expect(
            (request as AbortableMultipartRequest).abortTrigger, trigger);
      });

      test('builds standard MultipartRequest when trigger is null + multipart',
          () {
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          onSuccessCallback: (_) {},
          multipartRequest: true,
        );

        final request = RequestBuilder.build(config);
        expect(request, isA<MultipartRequest>());
        expect(request, isNot(isA<AbortableMultipartRequest>()));
      });

      test('AbortableRequest preserves headers and body', () {
        final trigger = Future<void>.value();
        final body = {'key': 'value'};
        final headers = {'Authorization': 'Bearer token'};
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          header: headers,
          body: body,
          onSuccessCallback: (_) {},
          abortTrigger: trigger,
        );

        final request = RequestBuilder.build(config) as AbortableRequest;
        expect(request.headers['Authorization'], 'Bearer token');
        expect(request.body, jsonEncode(body));
      });

      test('AbortableMultipartRequest preserves files and fields', () {
        final trigger = Future<void>.value();
        final file = MultipartFile.fromString('test', 'content');
        final body = {'key': 'value'};
        final config = ConnectionConfig(
          type: EventFluxConnectionType.post,
          url: 'http://example.com/sse',
          multipartRequest: true,
          files: [file],
          body: body,
          onSuccessCallback: (_) {},
          abortTrigger: trigger,
        );

        final request =
            RequestBuilder.build(config) as AbortableMultipartRequest;
        expect(request.files.single, file);
        expect(request.fields, body);
      });
    });
  });
}
