library dart_remarkable_api;

import 'dart:convert';

import 'package:dart_remarkable_api/model/trash.dart';
import 'package:dart_remarkable_api/remarkable_http_client.dart';
import 'package:dart_remarkable_api/untils.dart';

import 'model/entity.dart';
import 'model/root.dart';

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
  final RemarkableHttpClient _rmHttpClient;

  RemarkableClient({
    RemarkableHttpClient? rmHttpClient,
    this.deviceToken,
    this.userToken,
  }) : this._rmHttpClient = rmHttpClient ?? RemarkableHttpClient();

  bool get isAuth => deviceToken != null && userToken != null;

  Future<void> registerDevice(String code) async {
    var response = await _rmHttpClient.post(DEVICE_TOKEN_URL, body: {
      "code": code,
      "deviceDesc": DEVICE,
      "deviceID": newUuidV4(),
    });
    if (response.statusCode == 200) {
      deviceToken = response.body;
    } else {
      throw "Error registering device, status: ${response.statusCode}, body: ${response.body}";
    }
  }

  Future<void> renewToken() async {
    if (deviceToken == null) throw "deviceToken is null";

    var response = await _rmHttpClient.post(
      USER_TOKEN_URL,
      auth: deviceToken,
    );
    if (response.statusCode == 200) {
      userToken = response.body;
    } else {
      throw "Error renewing token, status: ${response.statusCode}, body: ${response.body}";
    }
  }

  Future<Root> getRoot() async {
    var response = await _rmHttpClient.get(
      "/document-storage/json/2/docs",
      auth: userToken,
    );
    var jsonArray = jsonDecode(response.body);

    Map<String, Entity> allEntities = {};
    var root = Root(children: []);
    allEntities[""] = root;
    allEntities["trash"] = Trash(children: []);
    for (final entityJson in jsonArray) {
      var entity = Entity.parse(entityJson);
      allEntities[entity.id] = entity;
    }

    for (final entity in allEntities.values) {
      entity.linkRelationship(allEntities);
    }

    return root;
  }
}
