// This code is adapted from fetch_client package
// Copyright (c) 2023-2024 Yaroslav Vorobev and contributors
// Licensed under the MIT License

import 'package:fetch_client/fetch_client.dart';

/// The mode used to determine if cross-origin requests lead to valid responses,
/// and which properties of the response are readable.
enum WebConfigRequestMode {
  /// If a request is made to another origin with this mode set,
  /// the result is an error. You could use this to ensure that
  /// a request is always being made to your origin.
  sameOrigin,

  /// Prevents the method from being anything other than `HEAD`, `GET` or `POST`,
  /// and the headers from being anything other than simple headers.
  /// If any `ServiceWorkers` intercept these requests, they may not add
  /// or override any headers except for those that are simple headers.
  /// In addition, JavaScript may not access any properties of the resulting
  /// Response. This ensures that ServiceWorkers do not affect the semantics
  /// of the Web and prevents security and privacy issues arising from leaking
  /// data across domains.
  noCors,

  /// Allows cross-origin requests, for example to access various APIs
  /// offered by 3rd party vendors. These are expected to adhere to
  /// the CORS protocol. Only a limited set of headers are exposed
  /// in the Response, but the body is readable.
  cors,

  /// A mode for supporting navigation. The navigate value is intended
  /// to be used only by HTML navigation. A navigate request
  /// is created only while navigating between documents.
  navigate,

  /// A special mode used only when establishing a WebSocket connection.
  webSocket;

  RequestMode toRequestMode() => switch (this) {
        WebConfigRequestMode.sameOrigin => RequestMode.sameOrigin,
        WebConfigRequestMode.noCors => RequestMode.noCors,
        WebConfigRequestMode.cors => RequestMode.cors,
        WebConfigRequestMode.navigate => RequestMode.navigate,
        WebConfigRequestMode.webSocket => RequestMode.webSocket,
      };
}
