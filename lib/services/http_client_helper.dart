import 'package:http/http.dart' as http;
import 'http_client_helper_stub.dart'
    if (dart.library.js_interop) 'http_client_helper_web.dart';

final http.Client globalHttpClient = createHttpClient();

http.Client getHttpClient() => globalHttpClient;
