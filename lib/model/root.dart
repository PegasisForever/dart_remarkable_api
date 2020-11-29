import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/entity.dart';
import 'package:dart_remarkable_api/model/entity_response.dart';
import 'package:dart_remarkable_api/model/folder.dart';

class Root extends Folder {
  final Map<String,Entity> allEntities;

  Root({
    required RemarkableClient client,
    required Set<Entity> children,
    required this.allEntities,
  }) : super(
          client: client,
          entityResponse: EntityResponseSucceeded.empty(
            "",
            EntityType.COLLECTION,
            "Root",
          ),
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

  @override
  Future<void> refresh(bool withBlob) async {
    return;
  }
}
