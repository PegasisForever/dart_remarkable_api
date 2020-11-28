import 'package:dart_remarkable_api/model/entity.dart';

class Document extends Entity {
  final int currentPage;

  Document({
    required String id,
    required int version,
    required String message,
    required bool success,
    required String blobURLGet,
    required DateTime blobURLGetExpires,
    required DateTime modifiedClient,
    required String displayName,
    required this.currentPage,
    required bool bookmarked,
    required parentId,
    required parent,
  }) : super(
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
}
