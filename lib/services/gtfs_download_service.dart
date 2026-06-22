import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/app_log.dart';

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

  Future<List<int>> downloadFeed(
    String downloadUrl, {
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    AppLog.d('GtfsDownloadService: downloading $downloadUrl');
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request).timeout(
            const Duration(minutes: 10),
          );

      if (response.statusCode != 200) {
        throw HttpException(
          'Download failed (${response.statusCode}) for $downloadUrl',
        );
      }

      final totalBytes = response.contentLength;
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        onProgress?.call(
          bytes.length,
          totalBytes != null && totalBytes > 0 ? totalBytes : null,
        );
      }

      if (bytes.isEmpty) {
        throw const HttpException('Downloaded GTFS feed was empty.');
      }

      return bytes;
    } finally {
      client.close();
    }
  }

  Future<File> saveFeedZip({
    required String feedId,
    required List<int> bytes,
  }) async {
    final zipFile = await feedDirectory(feedId);
    await zipFile.writeAsBytes(bytes, flush: true);
    AppLog.d('GtfsDownloadService: saved ${zipFile.path}');
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
      AppLog.d('GtfsDownloadService: deleted $feedId');
    }
  }
}
