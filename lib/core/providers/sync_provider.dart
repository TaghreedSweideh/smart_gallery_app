import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/user_manager.dart';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  final ImageService _imageService;

  bool syncing = false;
  double progress = 0.0;

  SyncProvider(this._syncService, this._imageService);

  Future<void> startIfNeeded({
    int initialBatch = 800,
    int lookback = 800,
  }) async {
    if (syncing) {
      debugPrint('SyncProvider.startIfNeeded: already syncing');
      return;
    }
    debugPrint('SyncProvider.startIfNeeded called');
    await syncNewImages(initialBatch: initialBatch, lookback: lookback);
  }

  Future<void> syncNewImages({
    int initialBatch = 800,
    int lookback = 800,
  }) async {
    final userId = await UserManager.getUserId();
    if (userId == null) {
      debugPrint('SyncProvider.syncNewImages: no user id, abort');
      return;
    }
    debugPrint('SyncProvider.syncNewImages: userId=$userId');

    syncing = true;
    progress = 0.0;
    notifyListeners();

    try {
      final galleryReady = await _imageService.initGallery();
      debugPrint('SyncProvider.syncNewImages: galleryReady=$galleryReady');
      if (!galleryReady) {
        syncing = false;
        progress = 1.0;
        notifyListeners();
        return;
      }

      final syncedPaths = await _syncService.getSyncedImages();
      debugPrint(
        'SyncProvider.syncNewImages: syncedPathsCount=${syncedPaths.length}',
      );

      List<AssetEntity> candidateAssets;
      if (syncedPaths.isEmpty) {
        debugPrint(
          'SyncProvider: first sync, fetching recent $initialBatch assets',
        );
        candidateAssets = await _imageService.getRecentImages(
          count: initialBatch,
        );
      } else {
        debugPrint(
          'SyncProvider: subsequent sync, fetching recent $lookback assets',
        );
        candidateAssets = await _imageService.getRecentImages(count: lookback);
      }

      debugPrint('SyncProvider: candidateAssets=${candidateAssets.length}');

      // Build files + phonePaths aligned lists
      final List<File> files = [];
      final List<String> phonePaths = [];

      for (final asset in candidateAssets) {
        try {
          final f = await asset.file;
          if (f == null) continue;

          // Determine "phone path": prefer asset.relativePath (Android), else file.path
          String phonePath = '';
          try {
            // relativePath is available on Android; guard with try/catch in case of older versions
            phonePath = asset.relativePath ?? '';
          } catch (_) {
            phonePath = '';
          }
          if (phonePath.trim().isEmpty) phonePath = f.path;

          // skip if already synced (based on file.path saved previously)
          if (syncedPaths.contains(f.path)) {
            continue;
          }

          files.add(f);
          phonePaths.add(phonePath);
        } catch (e, st) {
          debugPrint(
            'SyncProvider: failed to get file for asset ${asset.id}: $e\n$st',
          );
        }
      }

      debugPrint(
        'SyncProvider: prepared files=${files.length} phonePaths=${phonePaths.length}',
      );

      if (files.isEmpty) {
        debugPrint('SyncProvider: nothing to upload');
        syncing = false;
        progress = 1.0;
        notifyListeners();
        return;
      }

      final success = await _syncService.uploadImages(
        userId: userId,
        images: files,
        onProgress: (p) {
          progress = p;
          notifyListeners();
        },
      );

      if (success) {
        debugPrint('SyncProvider: upload completed successfully');
      } else {
        debugPrint('SyncProvider: upload failed');
      }
    } catch (e, st) {
      debugPrint('SyncProvider.syncNewImages exception: $e\n$st');
    } finally {
      syncing = false;
      progress = 1.0;
      notifyListeners();
    }
  }
}
