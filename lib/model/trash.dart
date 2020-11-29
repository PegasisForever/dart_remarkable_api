import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/entity.dart';
import 'package:dart_remarkable_api/model/folder.dart';

class Trash extends Folder {
  Trash({
    required RemarkableClient client,
    required List<Entity> children,
  }) : super(
          client: client,
          id: "trash",
          version: 1,
          message: "",
          success: true,
          blobURLGet: "",
          blobURLGetExpires: DateTime.parse("0001-01-01T00:00:00Z"),
          modifiedClient: DateTime.parse("0001-01-01T00:00:00Z"),
          displayName: "Trash",
          bookmarked: false,
          parentId: "",
          parent: null,
          children: children,
        );
}
