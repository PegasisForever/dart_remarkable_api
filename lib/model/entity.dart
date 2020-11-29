import 'dart:convert';

import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/document.dart';
import 'package:dart_remarkable_api/model/folder.dart';
import 'package:dart_remarkable_api/model/root.dart';
import 'package:meta/meta.dart';

// Class hierarchy:
// Entity
//   Document
//   Folder
//     Root
//     Trash
abstract class Entity {
  final RemarkableClient client;

  // When this is the root: an empty string, else: always an UUID
  final String id;
  int version;

  DateTime modifiedClient;
  String displayName;
  bool bookmarked;

  // When the parent is root or this is the root: an empty string, else: always an UUID
  final String parentId;

  // is null until [linkRelationship] is used, always null for [Root]
  Folder? parent;

  bool isDeleted = true;

  Entity({
    required this.client,
    required EntityResponseSucceeded entityResponse,
  })   : id = entityResponse.id,
        version = entityResponse.version,
        modifiedClient = entityResponse.modifiedClient,
        displayName = entityResponse.displayName,
        bookmarked = entityResponse.bookmarked,
        parentId = entityResponse.parentId;

  factory Entity.create(
      RemarkableClient client, EntityResponse entityResponse) {
    if (entityResponse is EntityResponseFailed) {
      throw "non success response, message: ${entityResponse.message}";
    } else if (entityResponse is EntityResponseSucceeded) {
      if (entityResponse.type == EntityType.COLLECTION) {
        return Folder(
          client: client,
          entityResponse: entityResponse,
          children: Set(),
        );
      } else {
        return Document(
          client: client,
          entityResponse: entityResponse,
        );
      }
    } else {
      throw "Unknown EntityResponse type: ${entityResponse.runtimeType}";
    }
  }

  @protected
  void update(EntityResponse entityResponse) {
    if (entityResponse is EntityResponseFailed) {
      isDeleted = true;
    } else if (entityResponse is EntityResponseSucceeded) {
      if (entityResponse.id != id) throw "new id is different";
      version = entityResponse.version;
      modifiedClient = entityResponse.modifiedClient;
      displayName = entityResponse.displayName;
      bookmarked = entityResponse.bookmarked;
      var newParentId = entityResponse.parentId;
      // todo add testcases
      if (newParentId != parentId) {
        var oldParent = parent!;
        var allEntities = getRoot().allEntities;
        var newParent = allEntities[newParentId] as Folder;

        oldParent.children.remove(this);
        newParent.children.add(this);
        parent = newParent;
      }
    } else {
      throw "Unknown EntityResponse type: ${entityResponse.runtimeType}";
    }
  }

  Future<void> refresh(bool withBlob) async {
    var response = await client.rmHttpClient.get(
      "/document-storage/json/2/docs",
      auth: client.userToken,
      params: withBlob
          ? {
              "withBlob": "true",
              "doc": id,
            }
          : {
              "doc": id,
            },
    );
    var jsonArray = jsonDecode(response.body);
    update(EntityResponse(jsonArray[0]));
  }

  // map of id to entity
  void linkRelationship(Map<String, Entity> map) {
    parent = map[parentId] as Folder;
  }

  Root getRoot() {
    Entity curr = this;
    while (curr is! Root) curr = curr.parent!;
    return curr;
  }

  @override
  String toString() {
    return "${this.runtimeType}: ${this.displayName}";
  }
}

enum EntityType { DOCUMENT, COLLECTION }

EntityType parseEntityType(String str) {
  if (str == "CollectionType") {
    return EntityType.COLLECTION;
  } else if (str == "DocumentType") {
    return EntityType.DOCUMENT;
  } else {
    throw "Unsupported type: \"$str\"";
  }
}

String entityTypeToString(EntityType type) {
  if (type == EntityType.DOCUMENT) {
    return "DocumentType";
  } else {
    return "CollectionType";
  }
}

abstract class EntityResponse {
  factory EntityResponse(Map<String, dynamic> json) {
    if (_extractRequired(json, "Success")) {
      return EntityResponseSucceeded(json);
    } else {
      return EntityResponseFailed(json);
    }
  }

  EntityResponse._();
}

class EntityResponseFailed extends EntityResponse {
  final String message;

  EntityResponseFailed(Map<String, dynamic> json)
      : message = _extract(json, "Message") ?? "",
        super._();
}

class EntityResponseSucceeded extends EntityResponse {
  final String id;
  final int version;
  final String blobURLGet;
  final DateTime blobURLGetExpires;
  final DateTime modifiedClient;
  final EntityType type;
  final String displayName;
  final int currentPage;
  final bool bookmarked;
  final String parentId;

  EntityResponseSucceeded(Map<String, dynamic> json)
      : id = _extractRequired(json, "ID"),
        version = _extract(json, "Version") ?? 1,
        // success = _extract(json, "Success") ?? true,
        blobURLGet = _extract(json, "BlobURLGet") ?? "",
        blobURLGetExpires = DateTime.parse(
            _extract<String>(json, "BlobURLGetExpires") ??
                "0001-01-01T00:00:00Z"),
        modifiedClient = DateTime.parse(
            _extract<String>(json, "ModifiedClient") ?? "0001-01-01T00:00:00Z"),
        type = parseEntityType(_extractRequired(json, "Type")),
        displayName = _extractRequired(json, "VissibleName"),
        currentPage = _extract(json, "CurrentPage") ?? 0,
        bookmarked = _extract(json, "Bookmarked") ?? false,
        parentId = _extract(json, "Parent") ?? "",
        super._();

  // type: CollectionType or DocumentType
  factory EntityResponseSucceeded.empty(
      String id, EntityType type, String displayName) {
    return EntityResponseSucceeded({
      "ID": id,
      "Version": 1,
      "Message": "",
      "Success": true,
      "BlobURLGet": "",
      "BlobURLGetExpires": "0001-01-01T00:00:00Z",
      "ModifiedClient": "0001-01-01T00:00:00Z",
      "Type": entityTypeToString(type),
      "VissibleName": displayName,
      "CurrentPage": 0,
      "Bookmarked": false,
      "Parent": ""
    });
  }
}

T _extractRequired<T>(
  Map<String, dynamic> json,
  String key,
) {
  if (!json.containsKey(key))
    throw "Key \"$key\" not found in json ${jsonEncode(json)}";
  return json[key] as T;
}

T? _extract<T>(
  Map<String, dynamic> json,
  String key,
) {
  if (!json.containsKey(key))
    print("Warning: Key \"$key\" not found in json ${jsonEncode(json)}");
  return json[key] as T;
}
