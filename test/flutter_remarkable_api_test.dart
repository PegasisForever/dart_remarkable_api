import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_remarkable_api/flutter_remarkable_api.dart';

void main() {
  var client = RemarkableClient();

  test("register", () async {
    await client.registerDevice("htmqiidu"); // get from https://my.remarkable.com/connect/desktop
    expect(client.deviceToken, isNotNull);
  });
}
