// @dart=2.9

import 'dart:convert';
import 'dart:io';

import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/document.dart';
import 'package:dart_remarkable_api/model/entity.dart';
import 'package:dart_remarkable_api/model/folder.dart';
import 'package:dart_remarkable_api/model/root.dart';
import 'package:dart_remarkable_api/remarkable_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'dart_remarkable_api_test.mocks.dart';

http.Response mockResponse(int status, String body) {
  var response = MockResponse();
  when(response.statusCode).thenReturn(status);
  when(response.body).thenReturn(body);
  return response;
}

http.Response mockResponseFromFile(int status, String path) {
  return mockResponse(status, File(path).readAsStringSync());
}

const MOCK_SERVER_DATA_PATH = "test_data/mock_server/";

@GenerateMocks([http.Response, RemarkableHttpClient])
void main() {
  var rmHttpClient = MockRemarkableHttpClient();
  var client = RemarkableClient(
    rmHttpClient: rmHttpClient,
    dataPath: "./test_data/client",
  );

  group("Register", () {
    test('Register device', () async {
      expect(client.isAuth, equals(false));

      when(rmHttpClient.post(
        any,
        body: anyNamed("body"),
      )).thenAnswer((_) async => mockResponse(200, "device_token"));

      await client.registerDevice("123456");

      verifyInOrder([
        rmHttpClient.post(
          argThat(equals(DEVICE_TOKEN_URL)),
          body: argThat(
            allOf([
              containsPair("code", "123456"),
              contains("deviceDesc"),
              contains("deviceID"),
            ]),
            named: "body",
          ),
        ),
      ]);
      expect(client.deviceToken, equals("device_token"));
      expect(client.isAuth, equals(false));
    });

    test('Register device again', () async {
      expect(() async => await client.registerDevice("123456"),
          throwsA(isA<String>()));
    });

    test("Renew token", () async {
      when(rmHttpClient.post(
        any,
        auth: anyNamed("auth"),
      )).thenAnswer((_) async => mockResponse(200, "user_token"));

      await client.renewToken();

      verifyInOrder([
        rmHttpClient.post(
          argThat(equals(USER_TOKEN_URL)),
          auth: argThat(
            equals("device_token"),
            named: "auth",
          ),
        ),
      ]);
      expect(client.userToken, equals("user_token"));
      expect(client.isAuth, equals(true));
    });
  });

  group("Query (start without blob)", () {
    List<Root> root = [null];

    var fileList = getFileListWithoutBlob();

    test("getRoot throws no error", () async {
      when(rmHttpClient.get(
        any,
        auth: anyNamed("auth"),
      )).thenAnswer((_) async => mockResponse(200, jsonEncode(fileList)));

      root[0] = await client.getRoot(false);

      verifyInOrder([
        rmHttpClient.get(
          argThat(equals(DOCS_LIST_URL)),
          auth: argThat(
            equals("user_token"),
            named: "auth",
          ),
          params: argThat(
            isNull,
            named: "params",
          ),
        ),
      ]);
    });

    verifyFileStructure(root, {
      "82329c95-186e-4d07-99a3-782d2b5ff867": "",
      "19b21dd8-c3b1-4ca9-9b56-9178861ef890": {
        "a7f873de-f3af-4fdb-a5fd-6f34caaf6cfc": "",
        "97dd1a64-d721-4ef1-b9d7-6fe726b00aab": {},
      },
      "trash": {
        "fd5223e4-4688-42ed-8372-59235dc9bb3a": "",
        "4bed3e2c-c79b-4203-b87d-8ac9a6b70595": {
          "9f9d37da-a694-4ff9-a8b6-c29108050ed7": "",
          "9ac7b3f8-dd61-4a05-80dd-0506c34938fa": {},
        },
      },
    });

    test("Download files", () async {});
  });
}

void verifyFileStructure(List<Root> root, Map<String, dynamic> fileStructure) {
  group("Verify file tree", () {
    test("No circle in the tree", () async {
      var visited = Set<Entity>();
      void step(Entity entity) {
        expect(visited, isNot(contains(entity)));
        visited.add(entity);
        if (entity is Folder) {
          for (var child in entity.children.values) {
            step(child);
          }
        }
      }

      step(root[0]);
    });

    test("Parent & child relation is correct", () {
      for (var entity in root[0].allEntities.values) {
        if (entity is! Root) {
          expect(entity.parentId, equals(entity.parent.id));
          expect(entity.parent.children, contains(entity.id));
        }
      }
    });

    test("All files are in the correct position", () async {
      void step(Entity entity, dynamic fileStructure) {
        expect(fileStructure, anyOf(isA<String>(), isA<Map>()));
        if (fileStructure is String) {
          expect(entity, isA<Document>());
        } else if (fileStructure is Map) {
          expect(entity, isA<Folder>());
          var folder = entity as Folder;
          expect(
            folder.children.values.map((e) => e.id),
            containsAll(fileStructure.keys),
          );
          for (var child in folder.children.values) {
            step(child, fileStructure[child.id]);
          }
        }
      }

      step(root[0], fileStructure);
    });
  });
}

List<dynamic> getFileListWithoutBlob() {
  return jsonDecode(
      File(MOCK_SERVER_DATA_PATH + "list.json").readAsStringSync());
}

List<dynamic> getFileListWithBlob({bool expired = false}) {
  var fileList =
      jsonDecode(File(MOCK_SERVER_DATA_PATH + "list.json").readAsStringSync());
  for (var fileMap in fileList) {
    fileMap["BlobURLGet"] = "mock://" + fileMap["ID"];
    if (expired) {
      fileMap["BlobURLGetExpires"] =
          DateTime.now().subtract(Duration(days: 1)).toUtc().toIso8601String();
    } else {
      fileMap["BlobURLGetExpires"] =
          DateTime.now().add(Duration(days: 1)).toUtc().toIso8601String();
    }
  }
  return fileList;
}
