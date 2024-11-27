// This code is adapted from fetch_client package
// Copyright (c) 2023-2024 Yaroslav Vorobev and contributors
// Licensed under the MIT License

import 'package:fetch_client/fetch_client.dart';

/// How requests should handle redirects.
enum WebConfigRedirectPolicy {
  /// Default policy - always follow redirects.
  /// If redirect occurs the only way to know about it is via response properties.
  alwaysFollow,

  /// Probe via HTTP `GET` request.
  probe,

  /// Same as [probe] but using `HEAD` method.
  probeHead;

  RedirectPolicy toRedirectPolicy() => switch (this) {
        WebConfigRedirectPolicy.alwaysFollow => RedirectPolicy.alwaysFollow,
        WebConfigRedirectPolicy.probe => RedirectPolicy.probe,
        WebConfigRedirectPolicy.probeHead => RedirectPolicy.probeHead,
      };
}
