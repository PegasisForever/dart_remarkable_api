import 'dart:convert';
import 'dart:io';

import 'package:dart_remarkable_api/dart_remarkable_api.dart';

const AUTH_FILE_PATH = "test_auth.json";

void saveAuth(RemarkableClient client) {
  var json = {
    "device_token": client.deviceToken,
    "user_token": client.userToken,
  };
  var file = File(AUTH_FILE_PATH);
  file.writeAsStringSync(jsonEncode(json));
}

RemarkableClient loadAuth() {
  var file = File(AUTH_FILE_PATH);
  var json = jsonDecode(file.readAsStringSync());
  return RemarkableClient(
    deviceToken: json["device_token"],
    userToken: json["user_token"],
  );
}
