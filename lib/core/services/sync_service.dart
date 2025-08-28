import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class SyncService {
  static const _keySyncedImages = 'synced_images';

  /// Get already synced images
  Future<List<String>> getSyncedImages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySyncedImages) ?? [];
  }

  /// Save synced images
  Future<void> addSyncedImages(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getSyncedImages();
    final updated = [...existing, ...paths];
    await prefs.setStringList(_keySyncedImages, updated);
  }

  /// Upload images in batches
  Future<void> uploadImages({
    required String userId,
    required List<File> allImages,
    required void Function(double progress)? onProgress,
    int batchSize = 20,
  }) async {
    final syncedPaths = await getSyncedImages();
    final newImages = allImages
        .where((img) => !syncedPaths.contains(img.path))
        .toList();

    int total = newImages.length;
    int uploadedCount = 0;

    for (int i = 0; i < newImages.length; i += batchSize) {
      final batch = newImages.skip(i).take(batchSize).toList();

      var uri = Uri.parse('https://yourserver.com/api/upload');
      var request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = userId;

      for (var img in batch) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            img.path,
            filename: path.basename(img.path),
          ),
        );
      }

      // Send request
      var streamedResponse = await request.send();

      // Listen to upload progress
      final contentLength = streamedResponse.contentLength ?? 1;
      int bytesSent = 0;

      streamedResponse.stream
          .listen((chunk) {
            bytesSent += chunk.length;
            double batchProgress = bytesSent / contentLength;
            double overallProgress =
                (uploadedCount + batchProgress * batch.length) / total;
            if (onProgress != null) onProgress(overallProgress);
          })
          .onDone(() async {
            uploadedCount += batch.length;
            await addSyncedImages(batch.map((e) => e.path).toList());
          });

      await streamedResponse.stream.drain(); // ensure completion
    }
  }
}
