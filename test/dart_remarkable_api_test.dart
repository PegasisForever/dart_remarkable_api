// @dart=2.9

import 'package:dart_remarkable_api/model/document.dart';
import 'package:dart_remarkable_api/model/root.dart';
import 'package:test/test.dart';

import 'utils.dart';

const AUTH_FILE_PATH = "test_auth.json";

void main() {
  var client = loadAuth();

  test("renewToken", () async {
    var oldUserToken = client.userToken;
    await client.renewToken();
    expect(client.userToken == oldUserToken, equals(false));
    expect(client.isAuth, equals(true));

    saveAuth(client);
  });

  Root root;
  test("getRootEntities", () async {
    root = await client.getRoot(false);
  });

  test("download", () async {
    Document c = root.children.firstWhere(
        (child) => child.displayName.contains("LVM") && child is Document);
    await c.download();
    expect(await c.isDownloaded(), equals(true));
  });
}
