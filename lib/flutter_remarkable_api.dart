library flutter_remarkable_api;

import 'package:flutter_remarkable_api/remarkable_http_client.dart';
import 'package:uuid/uuid.dart';

const BASE_URL =
    "https://document-storage-production-dot-remarkable-production.appspot.com";
const DEVICE_TOKEN_URL = "https://my.remarkable.com/token/json/2/device/new";
const USER_TOKEN_URL = "https://my.remarkable.com/token/json/2/user/new";
const DEVICE = "desktop-windows";
const SERVICE_MGR_URL =
    "https://service-manager-production-dot-remarkable-production.appspot.com";

class RemarkableClient {
  String? deviceToken;
  String? userToken;
  String? userAgent;
  final RemarkableHttpClient _rmHttpClient;
  final _uuid = Uuid();

  RemarkableClient({RemarkableHttpClient? rmHttpClient})
      : this._rmHttpClient = rmHttpClient ?? RemarkableHttpClient();

  Future<void> registerDevice(String code) async {
    var response = await _rmHttpClient.post(DEVICE_TOKEN_URL, body: {
      "code": code,
      "deviceDesc": DEVICE,
      "deviceID": _uuid.v4().toString(),
    });
    if (response.statusCode == 200) {
      deviceToken = response.body;
    } else {
      throw "Error registering device, status: ${response.statusCode}, body: ${response.body}";
    }
  }
}
