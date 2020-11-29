library dart_remarkable_api;

import 'dart:convert';

import 'package:dart_remarkable_api/model/entity_response.dart';
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
  String dataPath;
  final RemarkableHttpClient rmHttpClient;

  RemarkableClient({
    required this.dataPath,
    RemarkableHttpClient? rmHttpClient,
    this.deviceToken,
    this.userToken,
  }) : this.rmHttpClient = rmHttpClient ?? RemarkableHttpClient();

  bool get isAuth => deviceToken != null && userToken != null;

  Future<void> registerDevice(String code) async {
    var response = await rmHttpClient.post(DEVICE_TOKEN_URL, body: {
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

    var response = await rmHttpClient.post(
      USER_TOKEN_URL,
      auth: deviceToken,
    );
    if (response.statusCode == 200) {
      userToken = response.body;
    } else {
      throw "Error renewing token, status: ${response.statusCode}, body: ${response.body}";
    }
  }

  // withBlob:
  // true: get download links for all documents, but with performance
  // penalty (~3s), use when you are going to download all documents
  // afterwards
  // false: without download links (~0.5s), use when you only need a list of
  // documents. When you call [download] method on a document instance later,
  // it will send an extra request to get the download link for that individual
  // document before downloading.
  Future<Root> getRoot(bool withBlob) async {
    var response = await rmHttpClient.get(
      "/document-storage/json/2/docs",
      auth: userToken,
      params: withBlob ? {"withBlob": "true"} : null,
    );
    var jsonArray = jsonDecode(response.body);

    Map<String, Entity> allEntities = {};
    var root = Root(client: this, children: Set(), allEntities: allEntities);
    allEntities[""] = root;
    allEntities["trash"] = Trash(client: this, children: Set());
    for (final entityJson in jsonArray) {
      var entity = Entity.create(this, EntityResponse(entityJson));
      allEntities[entity.id] = entity;
    }

    for (final entity in allEntities.values) {
      entity.linkRelationship(allEntities);
    }

    // todo remove files on disk but not in the root tree (deleted files)
    return root;
  }
}
