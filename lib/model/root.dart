import 'package:dart_remarkable_api/model/entity.dart';
import 'package:dart_remarkable_api/model/folder.dart';

class Root extends Folder {
  Root({
    required List<Entity> children,
  }) : super(
          id: "",
          version: 1,
          message: "",
          success: true,
          blobURLGet: "",
          blobURLGetExpires: DateTime.parse("0001-01-01T00:00:00Z"),
          modifiedClient: DateTime.parse("0001-01-01T00:00:00Z"),
          displayName: "Root",
          bookmarked: false,
          parentId: "",
          parent: null,
          children: children,
        );

  @override
  void linkRelationship(Map<String, Entity> map) {
    for (final entity in map.values) {
      if (entity is! Root && entity.parentId == id) {
        children.add(entity);
      }
    }
  }
}
