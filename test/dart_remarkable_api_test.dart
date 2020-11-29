// @dart=2.9

import 'package:dart_remarkable_api/model/document.dart';
import 'package:dart_remarkable_api/model/entity.dart';
import 'package:dart_remarkable_api/model/root.dart';
import 'package:dart_remarkable_api/untils.dart';
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

  test("deleted document", () async {
    var d = Document(
      client: client,
      entityResponse: EntityResponseSucceeded.empty(
        newUuidV4(),
        EntityType.DOCUMENT,
        "test",
      ),
    );

    expect(d.isDeleted, equals(false));
    await d.refresh(true);
    expect(d.isDeleted, equals(true));
  });
}
