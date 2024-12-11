// This code is adapted from fetch_client package
// Copyright (c) 2023-2024 Yaroslav Vorobev and contributors
// Licensed under the MIT License

import 'package:eventflux/models/web_config/request_mode.dart';
import 'package:fetch_client/fetch_client.dart';

/// Controls how requests will interact with the browser's HTTP cache.
enum WebConfigRequestCache {
  /// The browser looks for a matching request in its HTTP cache.
  ///
  /// * If there is a match and it is fresh, it will be returned from the cache.
  /// * If there is a match but it is stale, the browser will make
  ///   a conditional request to the remote server. If the server indicates
  ///   that the resource has not changed, it will be returned from the cache.
  ///   Otherwise the resource will be downloaded from the server and
  ///   the cache will be updated.
  /// * If there is no match, the browser will make a normal request,
  ///   and will update the cache with the downloaded resource.
  byDefault,

  /// The browser fetches the resource from the remote server
  /// without first looking in the cache, and will not update the cache
  /// with the downloaded resource.
  noStore,

  /// The browser fetches the resource from the remote server
  /// without first looking in the cache, but then will update the cache
  /// with the downloaded resource.
  reload,

  /// The browser looks for a matching request in its HTTP cache.
  ///
  /// * If there is a match, fresh or stale, the browser will make
  ///   a conditional request to the remote server. If the server indicates
  ///   that the resource has not changed, it will be returned from the cache.
  ///   Otherwise the resource will be downloaded from the server and
  ///   the cache will be updated.
  /// * If there is no match, the browser will make a normal request,
  ///   and will update the cache with the downloaded resource.
  noCache,

  /// The browser looks for a matching request in its HTTP cache.
  ///
  /// * If there is a match, fresh or stale, it will be returned from the cache.
  /// * If there is no match, the browser will make a normal request,
  ///   and will update the cache with the downloaded resource.
  forceCache,

  /// The browser looks for a matching request in its HTTP cache.
  ///
  /// * If there is a match, fresh or stale, it will be returned from the cache.
  /// * If there is no match, the browser will respond
  ///   with a 504 Gateway timeout status.
  ///
  /// The [onlyIfCached] mode can only be used if the request's mode
  /// is [WebConfigRequestMode.sameOrigin].
  onlyIfCached;

  RequestCache toRequestCache() => switch (this) {
        WebConfigRequestCache.byDefault => RequestCache.byDefault,
        WebConfigRequestCache.noStore => RequestCache.noStore,
        WebConfigRequestCache.reload => RequestCache.reload,
        WebConfigRequestCache.noCache => RequestCache.noCache,
        WebConfigRequestCache.forceCache => RequestCache.forceCache,
        WebConfigRequestCache.onlyIfCached => RequestCache.onlyIfCached,
      };
}
