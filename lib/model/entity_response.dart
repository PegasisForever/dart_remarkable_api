import 'dart:convert';

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
