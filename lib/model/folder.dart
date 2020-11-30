import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/entity.dart';
import 'package:dart_remarkable_api/model/entity_response.dart';

class Folder extends Entity {
  // id to entity
  final Map<String, Entity> children;

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
    children.clear();
    for (final entity in map.values) {
      if (entity.parentId == id) {
        children[entity.id] = entity;
      }
    }
  }

  // Be careful! This method will not change the parent property of the entity,
  // you don't want to turn a file tree into a file graph.
  // Return the removed entity if the entity was in the map, else return null.
  Entity? removeChild(Entity entity) {
    return children.remove(entity.id);
  }

  // Be careful! This method will not change the parent property of the entity,
  // you don't want to turn a file tree into a file graph.
  // Return true if the child is added, return false if there is already a
  // child with the same id
  bool addChild(Entity entity) {
    if (children.containsKey(entity.id)) {
      return false;
    } else {
      children[entity.id] = entity;
      return true;
    }
  }
}
