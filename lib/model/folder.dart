import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/entity.dart';
import 'package:dart_remarkable_api/model/entity_response.dart';

class Folder extends Entity {
  final Set<Entity> children;

  Folder({
    required RemarkableClient client,
    required EntityResponseSucceeded entityResponse,
    required this.children,
  }) : super(
          client: client,
          entityResponse: entityResponse,
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
