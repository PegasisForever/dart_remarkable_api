// @dart=2.9

import 'package:dart_remarkable_api/remarkable_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'remarkable_http_client_test.mocks.dart';

class _URIMatcher extends Matcher {
  final String uriStr;

  _URIMatcher(this.uriStr);

  @override
  Description describe(Description description) {
    throw description.add("equals " + uriStr);
  }

  @override
  bool matches(item, Map matchState) {
    return item.toString() == uriStr;
  }
}

class _RequestMatcher extends Matcher {
  final String uriStr;
  final String method;
  final Map<String, String> headers;

  _RequestMatcher(this.uriStr, this.method, this.headers);

  @override
  Description describe(Description description) {
    throw description.add("equals $uriStr, method is $method");
  }

  @override
  bool matches(item, Map matchState) {
    var req = item as http.Request;
    for (MapEntry entry in headers.entries) {
      if (req.headers[entry.key] != entry.value) return false;
    }
    return req.url.toString() == uriStr && req.method == method;
  }
}

@GenerateMocks([
  http.Client,
  http.Response,
  http.StreamedResponse,
])
void main() {
  var httpClient = MockClient();
  var rmHttpClient = RemarkableHttpClient(
    httpClient: httpClient,
  );

  setUpAll(() {
    reset(httpClient);
  });

  test("Post", () async {
    when(httpClient.post(
      argThat(_URIMatcher("https://${DEFAULT_HOST}/index.html")),
      headers: argThat(
        allOf(
          containsPair("user-agent", DEFAULT_USER_AGENT),
          containsPair("Authorization", "Bearer auth"),
        ),
        named: "headers",
      ),
      body: argThat(
        equals("{}"),
        named: "body",
      ),
    )).thenAnswer((_) async => MockResponse());

    await rmHttpClient.post(
      "/index.html",
      auth: "auth",
      body: {},
    );
  });

  test("Get", () async {
    when(httpClient.get(
      argThat(_URIMatcher("https://${DEFAULT_HOST}/index.html?a=b")),
      headers: argThat(
        allOf(
          containsPair("user-agent", DEFAULT_USER_AGENT),
          containsPair("Authorization", "Bearer auth"),
        ),
        named: "headers",
      ),
    )).thenAnswer((_) async => MockResponse());

    await rmHttpClient.get(
      "/index.html",
      auth: "auth",
      params: {"a": "b"},
    );
  });

  test("Get streamed", () async {
    when(httpClient.send(
      argThat(_RequestMatcher(
        "https://${DEFAULT_HOST}/index.html?a=b",
        "GET",
        {
          "user-agent": DEFAULT_USER_AGENT,
          "Authorization": "Bearer auth",
        },
      )),
    )).thenAnswer((_) async => MockStreamedResponse());

    await rmHttpClient.getStreamed(
      "/index.html",
      auth: "auth",
      params: {"a": "b"},
    );
  });

  test("Put", () async {
    when(httpClient.put(
      argThat(_URIMatcher("https://${DEFAULT_HOST}/index.html")),
      headers: argThat(
        allOf(
          containsPair("user-agent", DEFAULT_USER_AGENT),
          containsPair("Authorization", "Bearer auth"),
        ),
        named: "headers",
      ),
      body: argThat(
        equals(""),
        named: "body",
      ),
    )).thenAnswer((_) async => MockResponse());

    await rmHttpClient.put(
      "/index.html",
      auth: "auth",
      data: "",
    );
  });
}
