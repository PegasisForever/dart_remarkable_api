import 'dart:convert';

import 'package:http/http.dart' as http;

const DEFAULT_HOST =
    "document-storage-production-dot-remarkable-production.appspot.com";
const DEFAULT_USER_AGENT = "dart_remarkable_api";

class RemarkableHttpClient {
  final String userAgent;
  final _httpClient;

  RemarkableHttpClient({
    this.userAgent = DEFAULT_USER_AGENT,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Map<String, String> _getHeaders({
    required String? auth,
  }) {
    Map<String, String> headers = {};
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
  }) async {
    return await _httpClient.post(
      _getUri(path),
      headers: _getHeaders(auth: auth),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get(
    String path, {
    String? auth,
    Map<String, dynamic>? params,
  }) async {
    return await _httpClient.get(
      _getUri(path).replace(queryParameters: params),
      headers: _getHeaders(auth: auth),
    );
  }

  Future<http.StreamedResponse> getStreamed(
    String path, {
    String? auth,
    Map<String, dynamic>? params,
  }) {
    var request = http.Request(
      "GET",
      _getUri(path).replace(queryParameters: params),
    )..headers.addAll(_getHeaders(auth: auth));
    return _httpClient.send(request);
  }

  Future<http.Response> put(
    String path, {
    String? auth,
    dynamic data,
  }) async {
    return await _httpClient.put(
      _getUri(path),
      headers: _getHeaders(auth: auth),
      body: data,
    );
  }
}
