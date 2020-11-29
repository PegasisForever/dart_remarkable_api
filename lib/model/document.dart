import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:dart_remarkable_api/dart_remarkable_api.dart';
import 'package:dart_remarkable_api/model/entity.dart';

enum DocumentType {
  NOTEBOOK,
  PDF,
  EPUB,
}

class Document extends Entity {
  final int currentPage;

  Document({
    required RemarkableClient client,
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

  Future<void> download() async {
    if (blobURLGetExpires.isBefore(DateTime.now())) {
      // todo refresh
    }

    var fileStream = await client.rmHttpClient.getStreamed(
      blobURLGet,
      auth: client.userToken,
    );
    if (fileStream.statusCode != 200)
      throw "status: ${fileStream.statusCode}, response: ${await fileStream.stream.bytesToString()}";

    // fixme
    // Dart archive package doesn't support read file from a stream, so I have
    // to read all file content into memory before unzipping.
    var fileBytes = await fileStream.stream.toBytes();
    var zip = await _unzip(fileBytes.toList());

    var basePath = client.dataPath + '/' + id;
    var baseDir = Directory(basePath);
    if (await baseDir.exists()) {
      await baseDir.delete(recursive: true);
    }
    for (final zipEntry in zip) {
      if (zipEntry.isFile) {
        final data = zipEntry.content as List<int>;
        var file = File(basePath + '/' + zipEntry.name);
        await file.create(recursive: true);
        await file.writeAsBytes(data);
      } else {
        var dir = Directory(basePath + '/' + zipEntry.name);
        await dir.create();
      }
    }
  }
}

Future<Archive> _unzip(List<int> bytes) async {
  var resultPort = ReceivePort();
  var errorPort = ReceivePort();
  Isolate.spawn(
    _unzipCompute,
    [bytes, resultPort.sendPort],
    onError: errorPort.sendPort,
  );
  errorPort.listen((message) {
    throw message;
  });
  var result = Completer<Archive>();
  resultPort.listen((message) {
    result.complete(message);
  });
  return await result.future;
}

void _unzipCompute(args) {
  var zip = ZipDecoder().decodeBytes(args[0]);
  args[1].send(zip);
}
