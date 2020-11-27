// @dart=2.9
import 'package:flutter_test/flutter_test.dart';

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

  test("getRootEntities", () async {
    var root = await client.getRoot();

  });
}
