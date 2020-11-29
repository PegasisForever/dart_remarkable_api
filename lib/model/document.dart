import 'dart:async';
import 'dart:convert';
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
  int currentPage;
  String blobURLGet;
  DateTime blobURLGetExpires;

  Document({
    required RemarkableClient client,
    required EntityResponseSucceeded entityResponse,
  })   : currentPage = entityResponse.currentPage,
        blobURLGet = entityResponse.blobURLGet,
        blobURLGetExpires = entityResponse.blobURLGetExpires,
        super(
          client: client,
          entityResponse: entityResponse,
        );

  Future<bool> isDownloaded() async {
    try {
      var metaDataFile = File(
          client.dataPath + '/' + id + '/.dart_remarkable_api_metadata.json');
      var metaData = jsonDecode(await metaDataFile.readAsString());
      return metaData["Version"] == version;
    } catch (_) {
      return false;
    }
  }

  Future<void> download() async {
    if (await isDownloaded()) return;
    if (blobURLGet.isEmpty || blobURLGetExpires.isBefore(DateTime.now()))
      await refresh(true);

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

    await deleteFilesOnDisk();
    var basePath = client.dataPath + '/' + id;
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
    var metaDataFile = File(basePath + '/.dart_remarkable_api_metadata.json');
    metaDataFile.writeAsString(jsonEncode({"Version": version}));
  }

  Future<void> deleteFilesOnDisk() async {
    var basePath = client.dataPath + '/' + id;
    var baseDir = Directory(basePath);
    if (await baseDir.exists()) {
      await baseDir.delete(recursive: true);
    }
  }

  @override
  void update(EntityResponse entityResponse) {
    super.update(entityResponse);
    if (entityResponse is EntityResponseFailed) {
      // do nothing
    } else if (entityResponse is EntityResponseSucceeded) {
      currentPage = entityResponse.currentPage;
      blobURLGet = entityResponse.blobURLGet;
      blobURLGetExpires = entityResponse.blobURLGetExpires;
    } else {
      throw "Unknown EntityResponse type: ${entityResponse.runtimeType}";
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
