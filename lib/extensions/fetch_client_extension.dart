import 'package:eventflux/models/web_config/web_config.dart';
import 'package:fetch_client/fetch_client.dart';

extension FetchClientExtension on FetchClient {
  static FetchClient fromWebConfig(WebConfig webConfig) {
    return FetchClient(
      mode: webConfig.mode.toRequestMode(),
      credentials: webConfig.credentials.toRequestCredentials(),
      cache: webConfig.cache.toRequestCache(),
      referrer: webConfig.referrer,
      referrerPolicy: webConfig.referrerPolicy.toRequestReferrerPolicy(),
      redirectPolicy: webConfig.redirectPolicy.toRedirectPolicy(),
      streamRequests: webConfig.streamRequests,
    );
  }
}
