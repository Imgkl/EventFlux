// This code is adapted from fetch_client package
// Copyright (c) 2023-2024 Yaroslav Vorobev and contributors
// Licensed under the MIT License

import 'package:fetch_client/fetch_client.dart';

/// Controls what browsers do with credentials (cookies, HTTP authentication
/// entries, and TLS client certificates).
enum WebConfigRequestCredentials {
  /// Tells browsers to include credentials with requests to same-origin URLs,
  /// and use any credentials sent back in responses from same-origin URLs.
  sameOrigin,

  /// Tells browsers to exclude credentials from the request, and ignore
  /// any credentials sent back in the response (e.g., any Set-Cookie header).
  omit,

  /// Tells browsers to include credentials in both same- and cross-origin
  /// requests, and always use any credentials sent back in responses.
  cors;

  RequestCredentials toRequestCredentials() => switch (this) {
        WebConfigRequestCredentials.sameOrigin => RequestCredentials.sameOrigin,
        WebConfigRequestCredentials.omit => RequestCredentials.omit,
        WebConfigRequestCredentials.cors => RequestCredentials.cors,
      };
}
