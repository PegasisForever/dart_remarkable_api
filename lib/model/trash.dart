import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/entity.dart';
import 'package:dart_remarkable_api/model/entity_response.dart';
import 'package:dart_remarkable_api/model/folder.dart';

class Trash extends Folder {
  Trash({
    required RemarkableClient client,
    required Set<Entity> children,
  }) : super(
          client: client,
          entityResponse: EntityResponseSucceeded.empty(
            "trash",
            EntityType.COLLECTION,
            "Trash",
          ),
          children: {},
        );

  @override
  Future<void> refresh(bool withBlob) async {
    return;
  }
}
