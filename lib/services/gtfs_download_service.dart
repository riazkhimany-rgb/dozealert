import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GtfsDownloadService {
  static const _gtfsFolderName = 'gtfs';

  Directory? _gtfsDirectory;

  Future<Directory> _resolveGtfsDirectory() async {
    if (_gtfsDirectory != null) {
      return _gtfsDirectory!;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final gtfsDir = Directory('${appDir.path}/$_gtfsFolderName');
    if (!gtfsDir.existsSync()) {
      gtfsDir.createSync(recursive: true);
    }
    _gtfsDirectory = gtfsDir;
    return gtfsDir;
  }

  Future<File> feedDirectory(String feedId) async {
    final root = await _resolveGtfsDirectory();
    final feedDir = Directory('${root.path}/$feedId');
    if (!feedDir.existsSync()) {
      feedDir.createSync(recursive: true);
    }
    return File('${feedDir.path}/feed.zip');
  }

  Future<List<int>> downloadFeed(String downloadUrl) async {
    debugPrint('GtfsDownloadService: downloading $downloadUrl');
    final response = await http.get(Uri.parse(downloadUrl)).timeout(
          const Duration(minutes: 2),
        );

    if (response.statusCode != 200) {
      throw HttpException(
        'Download failed (${response.statusCode}) for $downloadUrl',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw const HttpException('Downloaded GTFS feed was empty.');
    }

    return response.bodyBytes;
  }

  Future<File> saveFeedZip({
    required String feedId,
    required List<int> bytes,
  }) async {
    final zipFile = await feedDirectory(feedId);
    await zipFile.writeAsBytes(bytes, flush: true);
    debugPrint('GtfsDownloadService: saved ${zipFile.path}');
    return zipFile;
  }

  Future<List<int>?> readSavedFeedZip(String feedId) async {
    final zipFile = await feedDirectory(feedId);
    if (!zipFile.existsSync()) {
      return null;
    }
    return zipFile.readAsBytes();
  }

  Future<bool> hasSavedFeed(String feedId) async {
    final zipFile = await feedDirectory(feedId);
    return zipFile.existsSync();
  }

  Future<void> deleteSavedFeed(String feedId) async {
    final root = await _resolveGtfsDirectory();
    final feedDir = Directory('${root.path}/$feedId');
    if (feedDir.existsSync()) {
      feedDir.deleteSync(recursive: true);
      debugPrint('GtfsDownloadService: deleted $feedId');
    }
  }
}
