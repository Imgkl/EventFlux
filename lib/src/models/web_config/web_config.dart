// This code is adapted from fetch_client package
// Copyright (c) 2023-2024 Yaroslav Vorobev and contributors
// Licensed under the MIT License

import 'redirect_policy.dart';
import 'request_cache.dart';
import 'request_credentials.dart';
import 'request_mode.dart';
import 'request_referrer_policy.dart';

export 'redirect_policy.dart';
export 'request_cache.dart';
export 'request_credentials.dart';
export 'request_mode.dart';
export 'request_referrer_policy.dart';

/// Configuration for web requests.
class WebConfig {
  /// Create a new web configuration.
  WebConfig({
    this.mode = WebConfigRequestMode.noCors,
    this.credentials = WebConfigRequestCredentials.sameOrigin,
    this.cache = WebConfigRequestCache.byDefault,
    this.referrer = '',
    this.referrerPolicy =
        WebConfigRequestReferrerPolicy.strictOriginWhenCrossOrigin,
    this.redirectPolicy = WebConfigRedirectPolicy.alwaysFollow,
    this.streamRequests = false,
  });

  /// The request mode.
  final WebConfigRequestMode mode;

  /// The credentials mode, defines what browsers do with credentials.
  final WebConfigRequestCredentials credentials;

  /// The cache mode which controls how requests will interact with
  /// the browser's HTTP cache.
  final WebConfigRequestCache cache;

  /// The referrer.
  /// This can be a same-origin URL, `about:client`, or an empty string.
  final String referrer;

  /// The referrer policy.
  final WebConfigRequestReferrerPolicy referrerPolicy;

  /// The redirect policy, defines how client should handle redirects.
  final WebConfigRedirectPolicy redirectPolicy;

  /// Whether to use streaming for requests.
  ///
  /// **NOTICE**: This feature is supported only in __Chromium 105+__ based browsers
  /// and requires server to be HTTP/2 or HTTP/3.
  final bool streamRequests;

  /// Creates a copy of this configuration with the given fields replaced with the new values.
  WebConfig copyWith({
    WebConfigRequestMode? mode,
    WebConfigRequestCredentials? credentials,
    WebConfigRequestCache? cache,
    String? referrer,
    WebConfigRequestReferrerPolicy? referrerPolicy,
    WebConfigRedirectPolicy? redirectPolicy,
    bool? streamRequests,
  }) {
    return WebConfig(
      mode: mode ?? this.mode,
      credentials: credentials ?? this.credentials,
      cache: cache ?? this.cache,
      referrer: referrer ?? this.referrer,
      referrerPolicy: referrerPolicy ?? this.referrerPolicy,
      redirectPolicy: redirectPolicy ?? this.redirectPolicy,
      streamRequests: streamRequests ?? this.streamRequests,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebConfig &&
        other.mode == mode &&
        other.credentials == credentials &&
        other.cache == cache &&
        other.referrer == referrer &&
        other.referrerPolicy == referrerPolicy &&
        other.redirectPolicy == redirectPolicy &&
        other.streamRequests == streamRequests;
  }

  @override
  int get hashCode => Object.hash(
        mode,
        credentials,
        cache,
        referrer,
        referrerPolicy,
        redirectPolicy,
        streamRequests,
      );
}
