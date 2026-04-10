import 'dart:convert';

import 'package:eventflux/enum.dart';
import 'package:eventflux/src/connection_config.dart';
import 'package:http/http.dart';

/// Stateless utility that builds an HTTP [BaseRequest] from a [ConnectionConfig].
///
/// Extracted from the request-construction block in `_start()`.
class RequestBuilder {
  const RequestBuilder._();

  /// Builds either a [MultipartRequest] or a standard [Request] based on
  /// [config.multipartRequest] and [config.files].
  ///
  /// When [config.abortTrigger] is non-null, uses the abortable variants
  /// ([AbortableRequest] / [AbortableMultipartRequest]) so the request can
  /// be cancelled mid-flight.
  static BaseRequest build(ConnectionConfig config) {
    final isMultipart = config.multipartRequest ||
        (config.files != null && config.files!.isNotEmpty);

    if (isMultipart) {
      return config.abortTrigger != null
          ? _buildAbortableMultipart(config)
          : _buildMultipart(config);
    }
    return config.abortTrigger != null
        ? _buildAbortableStandard(config)
        : _buildStandard(config);
  }

  static MultipartRequest _buildMultipart(ConnectionConfig config) {
    final request = MultipartRequest(
      config.type == EventFluxConnectionType.get ? 'GET' : 'POST',
      Uri.parse(config.url),
    );
    _applyMultipartFields(request, config);
    return request;
  }

  static AbortableMultipartRequest _buildAbortableMultipart(
      ConnectionConfig config) {
    final request = AbortableMultipartRequest(
      config.type == EventFluxConnectionType.get ? 'GET' : 'POST',
      Uri.parse(config.url),
      abortTrigger: config.abortTrigger,
    );
    _applyMultipartFields(request, config);
    return request;
  }

  static void _applyMultipartFields(
      MultipartRequest request, ConnectionConfig config) {
    if (config.header.isNotEmpty) {
      request.headers.addAll(config.header);
    }
    if (config.body != null) {
      request.fields.addAll(
        config.body!.map((key, value) => MapEntry(key, value)),
      );
    }
    if (config.files != null) {
      for (final file in config.files!) {
        request.files.add(file);
      }
    }
  }

  static Request _buildStandard(ConnectionConfig config) {
    final request = Request(
      config.type == EventFluxConnectionType.get ? 'GET' : 'POST',
      Uri.parse(config.url),
    );
    _applyStandardFields(request, config);
    return request;
  }

  static AbortableRequest _buildAbortableStandard(ConnectionConfig config) {
    final request = AbortableRequest(
      config.type == EventFluxConnectionType.get ? 'GET' : 'POST',
      Uri.parse(config.url),
      abortTrigger: config.abortTrigger,
    );
    _applyStandardFields(request, config);
    return request;
  }

  static void _applyStandardFields(Request request, ConnectionConfig config) {
    if (config.header.isNotEmpty) {
      request.headers.addAll(config.header);
    }
    if (config.body != null) {
      request.body = jsonEncode(config.body);
    }
  }
}
