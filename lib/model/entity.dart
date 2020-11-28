import 'dart:convert';

import 'package:dart_remarkable_api/model/document.dart';
import 'package:dart_remarkable_api/model/folder.dart';

// Class hierarchy:
// Entity
//   Document
//     Notebook
//     Pdf
//     Epub
//   Folder
//     Root
//     Trash
abstract class Entity {
  // When this is the root: an empty string, else: always an UUID
  final String id;
  final int version;

  // can be an empty string
  final String message;
  final bool success;

  // can be an empty string
  final String blobURLGet;
  final DateTime blobURLGetExpires;
  final DateTime modifiedClient;
  final String displayName;
  final bool bookmarked;

  // When the parent is root or this is the root: an empty string, else: always an UUID
  final String parentId;

  // is null until [linkRelationship] is used, always null for [Root]
  Entity? parent;

  Entity({
    required this.id,
    required this.version,
    required this.message,
    required this.success,
    required this.blobURLGet,
    required this.blobURLGetExpires,
    required this.modifiedClient,
    required this.displayName,
    required this.bookmarked,
    required this.parentId,
    required this.parent,
  });

  factory Entity.parse(Map<String, dynamic> json) {
    String type = _extractRequired(json, "Type");
    if (type != "CollectionType" && type != "DocumentType")
      throw "Unsupported type: $type";

    String id = _extractRequired(json, "ID");
    int version = _extract(json, "Version") ?? 1;
    String message = _extract(json, "Message") ?? "";
    bool success = _extract(json, "Success") ?? true;
    String blobURLGet = _extract(json, "BlobURLGet") ?? "";
    DateTime blobURLGetExpires = DateTime.parse(
        _extract<String>(json, "BlobURLGetExpires") ?? "0001-01-01T00:00:00Z");
    DateTime modifiedClient = DateTime.parse(
        _extract<String>(json, "ModifiedClient") ?? "0001-01-01T00:00:00Z");
    // yes, this is a typo in the remarkable api.
    String displayName = _extractRequired(json, "VissibleName");

    bool bookmarked = _extract(json, "Bookmarked") ?? false;
    String parentId = _extract(json, "Parent") ?? "";

    if (type == "CollectionType") {
      return Folder(
        id: id,
        version: version,
        message: message,
        success: success,
        blobURLGet: blobURLGet,
        blobURLGetExpires: blobURLGetExpires,
        modifiedClient: modifiedClient,
        displayName: displayName,
        bookmarked: bookmarked,
        parentId: parentId,
        parent: null,
        children: [],
      );
    } else {
      int currentPage = _extract(json, "CurrentPage") ?? 0;
      return Document(
        id: id,
        version: version,
        message: message,
        success: success,
        blobURLGet: blobURLGet,
        blobURLGetExpires: blobURLGetExpires,
        modifiedClient: modifiedClient,
        displayName: displayName,
        bookmarked: bookmarked,
        currentPage: currentPage,
        parentId: parentId,
        parent: null,
      );
    }
  }

  // map of id to entity
  void linkRelationship(Map<String, Entity> map) {
    parent = map[parentId];
  }

  @override
  String toString() {
    return "${this.runtimeType}: ${this.displayName}";
  }

  static T _extractRequired<T>(
    Map<String, dynamic> json,
    String key,
  ) {
    try {
      return json[key] as T;
    } catch (e) {
      throw "Key $key not found in json ${jsonEncode(json)}";
    }
  }

  static T? _extract<T>(
    Map<String, dynamic> json,
    String key,
  ) {
    try {
      return json[key] as T;
    } catch (e) {
      print("Warning: Key $key not found in json ${jsonEncode(json)}");
      return null;
    }
  }
}
