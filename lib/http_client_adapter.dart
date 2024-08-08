import 'package:http/http.dart';

abstract interface class HttpClientAdapter {
  Future<StreamedResponse> send(BaseRequest request);
}
