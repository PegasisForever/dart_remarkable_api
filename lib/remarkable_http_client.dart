import 'dart:convert';

import 'package:http/http.dart' as http;

const DEFAULT_HOST =
    "document-storage-production-dot-remarkable-production.appspot.com";
const DEFAULT_USER_AGENT = "flutter_remarkable_api";

class RemarkableHttpClient {
  final String userAgent;
  final _httpClient = http.Client();

  RemarkableHttpClient({
    this.userAgent = DEFAULT_USER_AGENT,
  });

  Map<String, String> _getHeaders({
    required Map<String, String>? inputHeaders,
    required String? userToken,
  }) {
    var headers = inputHeaders ?? {};
    headers["user-agent"] = userAgent;
    if (userToken != null) {
      headers["Authorization"] = "Bearer " + userToken;
    }

    return headers;
  }

  Future<http.Response> post(
    String path, {
    String? userToken,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    headers = headers ?? {};
    headers["user-agent"] = userAgent;
    if (userToken != null) {
      headers["Authorization"] = "Bearer " + userToken;
    }

    var uri = Uri.parse(path);
    if (uri.scheme == "") uri = uri.replace(scheme: "https");
    if (uri.host == "") uri = uri.replace(host: DEFAULT_HOST);

    return await _httpClient.post(
      uri,
      headers: _getHeaders(inputHeaders: headers, userToken: userToken),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> get(
    String path, {
    String? userToken,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
  }) async {
    headers = headers ?? {};
    headers["user-agent"] = userAgent;
    if (userToken != null) {
      headers["Authorization"] = "Bearer " + userToken;
    }

    var uri = Uri.parse(path);
    if (uri.scheme == "") uri = uri.replace(scheme: "https");
    if (uri.host == "") uri = uri.replace(host: DEFAULT_HOST);
    uri.replace(queryParameters: params);

    return await _httpClient.get(uri, headers: headers);
  }

  Future<http.Response> put(
    String path, {
    String? userToken,
    dynamic data,
    Map<String, String>? headers,
  }) async {
    headers = headers ?? {};
    headers["user-agent"] = userAgent;
    if (userToken != null) {
      headers["Authorization"] = "Bearer " + userToken;
    }

    var uri = Uri.parse(path);
    if (uri.scheme == "") uri = uri.replace(scheme: "https");
    if (uri.host == "") uri = uri.replace(host: DEFAULT_HOST);

    return await _httpClient.put(uri, headers: headers, body: data);
  }
}
