import 'dart:convert';

import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/document.dart';
import 'package:dart_remarkable_api/model/entity_response.dart';
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
          children: {},
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

        oldParent.removeChild(this);
        newParent.addChild(this);
        parent = newParent;
      }
    } else {
      throw "Unknown EntityResponse type: ${entityResponse.runtimeType}";
    }
  }

  Future<void> refresh(bool withBlob) async {
    var response = await client.rmHttpClient.get(
      DOCS_LIST_URL,
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


