// @dart=2.9
import 'package:test/test.dart';

import 'package:dart_remarkable_api/dart_remarkable_api.dart';

import 'utils.dart';

void main() {
  var client = RemarkableClient();

  test("registerDevice", () async {
    // get from https://my.remarkable.com/connect/desktop
    await client.registerDevice("byxlqynh");
    expect(client.deviceToken, isNotNull);

    saveAuth(client);
  });
}
