// This code is adapted from fetch_client package
// Copyright (c) 2023-2024 Yaroslav Vorobev and contributors
// Licensed under the MIT License

import 'package:fetch_client/fetch_client.dart';

/// Specifies the referrer policy to use for the request.
enum WebConfigRequestReferrerPolicy {
  strictOriginWhenCrossOrigin,
  noReferrer,
  noReferrerWhenDowngrade,
  sameOrigin,
  origin,
  strictOrigin,
  originWhenCrossOrigin,
  unsafeUrl;

  RequestReferrerPolicy toRequestReferrerPolicy() => switch (this) {
        WebConfigRequestReferrerPolicy.strictOriginWhenCrossOrigin =>
          RequestReferrerPolicy.strictOriginWhenCrossOrigin,
        WebConfigRequestReferrerPolicy.noReferrer =>
          RequestReferrerPolicy.noReferrer,
        WebConfigRequestReferrerPolicy.noReferrerWhenDowngrade =>
          RequestReferrerPolicy.noReferrerWhenDowngrade,
        WebConfigRequestReferrerPolicy.sameOrigin =>
          RequestReferrerPolicy.sameOrigin,
        WebConfigRequestReferrerPolicy.origin => RequestReferrerPolicy.origin,
        WebConfigRequestReferrerPolicy.strictOrigin =>
          RequestReferrerPolicy.strictOrigin,
        WebConfigRequestReferrerPolicy.originWhenCrossOrigin =>
          RequestReferrerPolicy.originWhenCrossOrigin,
        WebConfigRequestReferrerPolicy.unsafeUrl =>
          RequestReferrerPolicy.unsafeUrl,
      };
}
