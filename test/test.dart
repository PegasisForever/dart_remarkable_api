// @dart=2.9

import 'dart:convert';
import 'dart:io';

import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/entity.dart';
import 'package:dart_remarkable_api/model/folder.dart';
import 'package:dart_remarkable_api/model/root.dart';
import 'package:dart_remarkable_api/model/trash.dart';
import 'package:dart_remarkable_api/remarkable_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'test.mocks.dart';

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
    Root root;
    group("getRoot without blob", () {
      var fileList = getFileListWithoutBlob();

      test("getRoot throws no error", () async {
        when(rmHttpClient.get(
          any,
          auth: anyNamed("auth"),
        )).thenAnswer((_) async => mockResponse(200, jsonEncode(fileList)));

        root = await client.getRoot(false);
      });

      test("All entity is included", () async {
        // +2 (root and trash)
        expect(root.allEntities.length, equals(fileList.length + 2));
        expect(root.allEntities, contains(""));
        expect(root.allEntities, contains("trash"));
        for (var fileMap in fileList) {
          expect(root.allEntities, contains(fileMap["ID"]));
        }
      });

      test("Parent & child relation is correct", () async {
        for (var entity in root.allEntities.values) {
          // if folder contains all its children
          if (entity is Folder) {
            for (var childFileMap in fileList
                .where((fileMap) => fileMap["Parent"] == entity.id)) {
              expect(entity.children, contains(childFileMap["ID"]));
            }
          }
          // if entity.parentId == entity.parent.id
          if (entity is! Root) {
            expect(entity.parentId, equals(entity.parent.id));
          }
          // if parent is correct
          if (entity is! Root && entity is! Trash) {
            expect(
                entity.parent.id,
                equals(fileList.firstWhere(
                    (fileMap) => fileMap["ID"] == entity.id)["Parent"]));
          }
        }
      });

      test("Tree structure is correct", () async {
        var visited = Set<Entity>();
        bool step(Entity entity) {
          expect(visited, isNot(contains(entity)));
          visited.add(entity);
          if (entity is Folder) {
            for (var child in entity.children.values) {
              step(child);
            }
          }
        }

        step(root);
      });
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
