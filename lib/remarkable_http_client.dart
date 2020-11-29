import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

const DEFAULT_HOST =
    "document-storage-production-dot-remarkable-production.appspot.com";
const DEFAULT_USER_AGENT = "dart_remarkable_api";

class RemarkableHttpClient {
  final String userAgent;
  final _httpClient = http.Client();

  RemarkableHttpClient({
    this.userAgent = DEFAULT_USER_AGENT,
  });

  Map<String, String> _getHeaders({
    required Map<String, String>? inputHeaders,
    required String? auth,
  }) {
    var headers = inputHeaders ?? {};
    headers["user-agent"] = userAgent;
    if (auth != null) {
      headers["Authorization"] = "Bearer " + auth;
    }

    return headers;
  }

  Uri _getUri(String path) {
    var uri = Uri.parse(path);
    if (uri.scheme == "") uri = uri.replace(scheme: "https");
    if (uri.host == "") uri = uri.replace(host: DEFAULT_HOST);

    return uri;
  }

  Future<http.Response> post(
    String path, {
    String? auth,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return await _httpClient.post(
      _getUri(path),
      headers: _getHeaders(inputHeaders: headers, auth: auth),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get(
    String path, {
    String? auth,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  }) async {
    _httpClient
        .send(Request("GET", _getUri(path).replace(queryParameters: params)));
    return await _httpClient.get(
      _getUri(path).replace(queryParameters: params),
      headers: _getHeaders(
        inputHeaders: headers,
        auth: auth,
      ),
    );
  }

  Future<StreamedResponse> getStreamed(
    String path, {
    String? auth,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  }) {
    var request = Request(
      "GET",
      _getUri(path).replace(queryParameters: params),
    )..headers.addAll(_getHeaders(
        inputHeaders: headers,
        auth: auth,
      ));
    return _httpClient.send(request);
  }

  Future<http.Response> put(
    String path, {
    String? auth,
    dynamic data,
    Map<String, String>? headers,
  }) async {
    return await _httpClient.put(
      _getUri(path),
      headers: _getHeaders(
        inputHeaders: headers,
        auth: auth,
      ),
      body: data,
    );
  }
}
