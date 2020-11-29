import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/entity.dart';

class Folder extends Entity {
  final List<Entity> children;

  Folder({
    required RemarkableClient client,
    required String id,
    required int version,
    required String message,
    required bool success,
    required String blobURLGet,
    required DateTime blobURLGetExpires,
    required DateTime modifiedClient,
    required String displayName,
    required bool bookmarked,
    required parentId,
    required parent,
    required this.children,
  }) : super(
          client: client,
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
          parent: parent,
        );

  @override
  void linkRelationship(Map<String, Entity> map) {
    super.linkRelationship(map);
    for (final entity in map.values) {
      if (entity.parentId == id) {
        children.add(entity);
      }
    }
  }
}
