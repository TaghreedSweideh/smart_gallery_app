import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  static const _keySyncedImages = 'synced_images';
  final ApiClient apiClient;

  SyncService({required this.apiClient});

  Future<List<String>> getSyncedImages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySyncedImages) ?? [];
  }

  Future<void> addSyncedImages(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_keySyncedImages) ?? [];
    final set = {...existing, ...paths};
    await prefs.setStringList(_keySyncedImages, set.toList());
  }

  /// Upload images in batches.phonePathsForAllImages must be same order as images.
  Future<bool> uploadImages({
    required String userId,
    required List<File> images,
    required void Function(double progress) onProgress,
    int batchSize = 20,
  }) async {
    debugPrint(
      'SyncService.uploadImages: start. totalImages=${images.length}, batchSize=$batchSize',
    );

    final synced = await getSyncedImages();
    final newImages = images.where((f) => !synced.contains(f.path)).toList();
    debugPrint(
      'SyncService.uploadImages: newImages after filtering=${newImages.length} (synced before=${synced.length})',
    );

    final total = newImages.length;
    if (total == 0) {
      onProgress(1.0);
      debugPrint('SyncService.uploadImages: nothing new to upload => done');
      return true;
    }

    int uploadedCount = 0;
    try {
      for (int i = 0; i < newImages.length; i += batchSize) {
        final batch = newImages.skip(i).take(batchSize).toList();
        debugPrint(
          'SyncService.uploadImages: uploading batch i=$i size=${batch.length}',
        );

        // For phone_paths we will send the file.path as the phone path here (SyncProvider will ideally supply nicer path)
        final phonePathsForBatch = batch.map((f) => f.path).toList();

        final resp = await apiClient.uploadImages(
          userId: userId,
          files: batch,
          phonePaths: phonePathsForBatch,
          onProgress: (p) {
            final overall = (uploadedCount + p * batch.length) / total;
            onProgress(overall.clamp(0.0, 1.0));
          },
        );

        if (resp == null) {
          debugPrint(
            'SyncService.uploadImages: batch failed at i=$i -> aborting',
          );
          return false;
        }

        await addSyncedImages(batch.map((f) => f.path).toList());
        uploadedCount += batch.length;
        debugPrint(
          'SyncService.uploadImages: batch success uploadedCount=$uploadedCount/$total',
        );

        onProgress((uploadedCount / total).clamp(0.0, 1.0));
      }

      onProgress(1.0);
      debugPrint('SyncService.uploadImages: all batches uploaded successfully');
      return true;
    } catch (e, st) {
      debugPrint('SyncService.uploadImages error: $e\n$st');
      return false;
    }
  }
}
