import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery_app/main.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/image_service.dart';

class GalleryProvider extends ChangeNotifier {
  final ImageService _imageService;

  GalleryProvider(this._imageService);

  // local device images
  final List<AssetEntity> _images = [];
  List<AssetEntity> get images => List.unmodifiable(_images);

  // server category images (paths from API)
  final List<String> _categoryImages = [];
  List<String> get categoryImages => List.unmodifiable(_categoryImages);

  bool loading = false;
  bool hasMore = true;

  bool _fetchingCategory = false;
  bool get isFetchingCategory => _fetchingCategory;

  final ValueNotifier<Set<String>> _selectionNotifier =
      ValueNotifier<Set<String>>({});
  Set<String> get selectedImageIds => _selectionNotifier.value;
  bool get isSelecting => _selectionNotifier.value.isNotEmpty;
  int get selectedCount => _selectionNotifier.value.length;

  int _page = 0;
  String? _currentCategoryId;

  // -------------------------
  // Selection management
  // -------------------------
  void toggleSelection(String imageId) {
    final newSelection = Set<String>.from(_selectionNotifier.value);
    if (newSelection.contains(imageId)) {
      newSelection.remove(imageId);
    } else {
      newSelection.add(imageId);
    }
    _selectionNotifier.value = newSelection;
    notifyListeners();
  }

  void clearSelection() {
    _selectionNotifier.value = {};
    notifyListeners();
  }

  /// Select all (includes both local asset ids and server file paths)
  void selectAll() {
    final combined = <String>{..._images.map((e) => e.id), ..._categoryImages};
    _selectionNotifier.value = combined;
    notifyListeners();
  }

  ValueNotifier<Set<String>> get selectionNotifier => _selectionNotifier;

  Future<bool> init({String? categoryId, int pageSize = 50}) async {
    try {
      final granted = await _imageService.initGallery();
      if (!granted) return false;
    } catch (e) {
      if (kDebugMode) print('GalleryProvider.init -> initGallery error: $e');
      return false;
    }

    _page = 0;
    _images.clear();
    _selectionNotifier.value = {};
    hasMore = true;
    _currentCategoryId = categoryId;
    await loadMore(size: pageSize);
    return true;
  }

  Future<void> loadMore({int size = 50, String? categoryId}) async {
    if (loading || !hasMore) return;

    loading = true;
    notifyListeners();

    final catId = categoryId ?? _currentCategoryId;

    try {
      final newImages = await _imageService.loadImages(
        page: _page,
        size: size,
        categoryId: catId,
      );

      if (newImages.isNotEmpty) {
        _images.addAll(newImages);
        _page++;
      } else {
        hasMore = false;
      }
    } catch (e) {
      if (kDebugMode) print('GalleryProvider.loadMore error: $e');
      hasMore = false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({int pageSize = 50}) async {
    _images.clear();
    _selectionNotifier.value = {};
    _page = 0;
    hasMore = true;
    await loadMore(size: pageSize);
  }

  // -------------------------
  // Server: fetch category images
  // -------------------------
  Future<void> fetchCategoryImages({
    required String userId,
    required int categoryId,
  }) async {
    _fetchingCategory = true;
    notifyListeners();

    try {
      final api = ApiClient(baseUrl: baseUrl);
      final data = await api.getCategoryImages(
        userId: userId,
        categoryId: categoryId,
      );

      if (data == null) {
        debugPrint('fetchCategoryImages: api returned null');
        _categoryImages.clear();
        return;
      }

      debugPrint('fetchCategoryImages: total paths returned=${data.length}');

      // keep raw list first
      final raw = List<String>.from(data);

      // filter existing files
      final existing = <String>[];
      int checked = 0;
      for (final p in raw) {
        if (p.trim().isEmpty) continue;
        try {
          checked++;
          final file = File(p);
          if (file.existsSync()) {
            existing.add(p);
          }
        } catch (e) {
          debugPrint(
            'fetchCategoryImages: error checking file.exists for "$p": $e',
          );
        }
        if (checked <= 10) {
          debugPrint('path[$checked]=$p exists=${File(p).existsSync()}');
        }
      }

      debugPrint(
        'fetchCategoryImages: existingPaths=${existing.length}/${raw.length}',
      );

      // show only the existing ones in UI
      _categoryImages
        ..clear()
        ..addAll(existing);

      if (existing.isEmpty) {
        debugPrint(
          'fetchCategoryImages: WARNING - no existing files found. '
          'This may be due to scoped storage, files deleted, or paths from another device.',
        );
      }
    } catch (e, st) {
      debugPrint("fetchCategoryImages error: $e\n$st");
    } finally {
      _fetchingCategory = false;
      notifyListeners();
    }
  }

  void clearLocalImagesAndSelection() {
    _images.clear();
    _selectionNotifier.value = {};
    hasMore = false;
    notifyListeners();
  }

  /// Helper to parse server response and return list of deleted phone paths
  List<String> _extractDeletedPathsFromResponse(
    Map<String, dynamic> resp,
    List<String> requestedPaths,
  ) {
    final List<String> deleted = [];

    // common key: 'deleted' -> list of strings
    if (resp['deleted'] is List) {
      for (final e in resp['deleted']) {
        if (e is String && e.isNotEmpty) deleted.add(e);
      }
      return deleted;
    }

    // backend returns 'results' map: { path: { ok: true/false, ... } }
    if (resp['results'] is Map) {
      final Map results = resp['results'] as Map;
      results.forEach((key, value) {
        try {
          final ok =
              (value is Map &&
              (value['ok'] == true || value['deleted'] == true));
          if (ok && key is String && key.isNotEmpty) deleted.add(key);
        } catch (_) {}
      });
      if (deleted.isNotEmpty) return deleted;
    }

    // if success == true assume requestedPaths deleted
    if (resp['success'] == true) {
      return List<String>.from(requestedPaths);
    }

    return deleted; // might be empty
  }

  /// Delete server images by phone paths (bulk). If `paths` is null will use current selection
  Future<void> deleteServerImages({
    required String? userId,
    List<String>? paths,
    bool removeFile = true,
  }) async {
    final sel = Set<String>.from(_selectionNotifier.value);
    // build phonePaths either from provided paths or from selection
    final phonePaths =
        (paths ??
                sel
                    .where((s) => s.contains('/') || s.startsWith('file://'))
                    .map((s) {
                      var p = s;
                      if (p.startsWith('file://')) {
                        p = p.replaceFirst('file://', '');
                      }
                      return p;
                    })
                    .toList())
            .where((p) => p.trim().isNotEmpty)
            .toList();

    if (phonePaths.isEmpty) return;

    try {
      final api = ApiClient(baseUrl: baseUrl);
      final resp = await api.deleteImagesByPaths(
        userId: userId,
        phonePaths: phonePaths,
        removeFile: removeFile,
      );

      if (resp == null) {
        debugPrint('deleteServerImages: api returned null');
        return;
      }

      // get list of actually deleted paths
      final deleted = _extractDeletedPathsFromResponse(resp, phonePaths);

      if (deleted.isEmpty) {
        debugPrint('deleteServerImages: no deleted paths in response: $resp');
        return;
      }

      // Remove deleted from _categoryImages
      _categoryImages.removeWhere((p) => deleted.contains(p));

      // Also try to delete local files if exist
      for (final p in deleted) {
        try {
          final f = File(p);
          if (f.existsSync()) {
            await f.delete();
            if (kDebugMode) {
              debugPrint('deleteServerImages: deleted local file $p');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'deleteServerImages: failed to delete local file $p -> $e',
            );
          }
        }
      }

      // Remove deleted from selection
      final newSel = Set<String>.from(_selectionNotifier.value);
      deleted.forEach(newSel.remove);
      _selectionNotifier.value = newSel;

      notifyListeners();
    } catch (e, st) {
      debugPrint('deleteServerImages error: $e\n$st');
    }
  }

  /// Delete a single server image (path) for user
  Future<void> deleteSingleServerImage({
    required String userId,
    required String phonePath,
    bool removeFile = true,
  }) async {
    var path = phonePath;
    if (path.startsWith('file://')) path = path.replaceFirst('file://', '');

    await deleteServerImages(
      userId: userId,
      paths: [path],
      removeFile: removeFile,
    );
  }

  /// Delete selected items with optimistic UI update.
  ///  - userId: if provided will be used to call server bulk delete for phonePaths.
  ///  - removeFile: pass to server whether to remove physical file on server side.
  /// Behaviour:
  /// 1) collect selection (asset ids + phone paths)
  /// 2) remove those entries from in-memory lists immediately and clear selection -> notifyListeners()
  /// 3) delete local assets via PhotoManager (if any)
  /// 4) attempt server bulk delete for phonePaths (if userId provided)
  /// 5) attempt to delete local files for phonePaths (best-effort, ignore missing files)
  Future<void> deleteSelectedImages({
    required String? userId,
    bool removeFile = true,
  }) async {
    final sel = Set<String>.from(_selectionNotifier.value);
    if (sel.isEmpty) return;

    // Separate asset IDs (no slash) and phonePaths (contain '/')
    final assetIds = <String>[];
    final phonePaths = <String>[];

    for (final id in sel) {
      if (id.contains('/') || id.startsWith('file://')) {
        var p = id;
        if (p.startsWith('file://')) p = p.replaceFirst('file://', '');
        phonePaths.add(p);
      } else {
        assetIds.add(id);
      }
    }

    // --- Optimistic update: remove from in-memory lists and clear selection immediately ---
    // Remove asset entities from _images
    if (assetIds.isNotEmpty) {
      _images.removeWhere((asset) => assetIds.contains(asset.id));
    }

    // Remove phonePaths from category images (we store raw paths)
    if (phonePaths.isNotEmpty) {
      _categoryImages.removeWhere((p) => phonePaths.contains(p));
    }

    // clear selection and notify UI immediately so gallery updates
    _selectionNotifier.value = {};
    notifyListeners();

    // Now perform the actual deletions (do not block UI)
    // We'll run in try/catch blocks and log errors but won't revert optimistic changes
    // 1) Delete local assets via PhotoManager
    try {
      if (assetIds.isNotEmpty) {
        await PhotoManager.editor.deleteWithIds(assetIds);
        if (kDebugMode) {
          debugPrint(
            'deleteSelectedBatch: deleted assetIds count=${assetIds.length}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('deleteSelectedBatch: PhotoManager.deleteWithIds error: $e');
      }
    }

    // 2) Call server to delete phone paths (if provided and userId available)
    if (phonePaths.isNotEmpty && userId != null && userId.isNotEmpty) {
      try {
        // call your existing API client function
        final api = ApiClient(baseUrl: baseUrl);
        final resp = await api.deleteImagesByPaths(
          userId: userId,
          phonePaths: phonePaths,
          removeFile: removeFile,
        );

        if (resp == null) {
          if (kDebugMode) {
            debugPrint('deleteSelectedBatch: server responded null');
          }
        } else {
          // get actual deleted list from server response
          final deleted = _extractDeletedPathsFromResponse(resp, phonePaths);
          if (deleted.isEmpty) {
            if (kDebugMode) {
              debugPrint('deleteSelectedBatch: server deleted none -> $resp');
            }
          } else {
            // ensure we removed returned deleted paths from local category images (already removed optimistically)
            _categoryImages.removeWhere((p) => deleted.contains(p));
            // also remove from selection if any left (selection already cleared but safe)
            final newSel = Set<String>.from(_selectionNotifier.value);
            deleted.forEach(newSel.remove);
            _selectionNotifier.value = newSel;
            notifyListeners();
            if (kDebugMode) {
              debugPrint(
                'deleteSelectedBatch: server deleted count=${deleted.length}',
              );
            }
          }
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('deleteSelectedBatch: server delete error: $e\n$st');
        }
      }
    }

    // 3) Try deleting local files for phonePaths (best-effort)
    if (phonePaths.isNotEmpty) {
      for (final p in phonePaths) {
        try {
          final f = File(p);
          if (f.existsSync()) {
            await f.delete();
            if (kDebugMode) {
              debugPrint('deleteSelectedBatch: deleted local file $p');
            }
          } else {
            if (kDebugMode) {
              debugPrint('deleteSelectedBatch: local file not found $p');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'deleteSelectedBatch: failed delete local file $p -> $e',
            );
          }
        }
      }
    }

    // end: nothing more to do (UI already updated).
  }
}
