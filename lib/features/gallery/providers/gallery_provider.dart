// gallery_provider.dart
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/services/image_service.dart';

class GalleryProvider extends ChangeNotifier {
  final ImageService _image_service;

  GalleryProvider(this._image_service);

  List<AssetEntity> images = [];
  bool loading = false;
  bool hasMore = true;

  // حالة الاختيار - نستخدم ValueNotifier للفصل
  final ValueNotifier<Set<String>> _selectionNotifier =
      ValueNotifier<Set<String>>({});
  Set<String> get selectedImageIds => _selectionNotifier.value;
  bool get isSelecting => _selectionNotifier.value.isNotEmpty;
  int get selectedCount => _selectionNotifier.value.length;

  int _page = 0;
  String? _currentCategoryId;

  // إدارة الاختيار
  void toggleSelection(String imageId) {
    final newSelection = Set<String>.from(_selectionNotifier.value);
    if (newSelection.contains(imageId)) {
      newSelection.remove(imageId);
    } else {
      newSelection.add(imageId);
    }
    _selectionNotifier.value = newSelection;
  }

  void clearSelection() {
    _selectionNotifier.value = {};
  }

  void selectAll() {
    _selectionNotifier.value = Set<String>.from(images.map((e) => e.id));
  }

  // للاستماع لتغييرات الاختيار فقط
  ValueNotifier<Set<String>> get selectionNotifier => _selectionNotifier;

  Future<void> deleteSelectedImages() async {
    if (_selectionNotifier.value.isEmpty) return;

    try {
      await PhotoManager.editor.deleteWithIds(
        _selectionNotifier.value.toList(),
      );

      images.removeWhere(
        (asset) => _selectionNotifier.value.contains(asset.id),
      );
      _selectionNotifier.value = {};

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error deleting images: $e');
      rethrow;
    }
  }

  // باقي الدوال تبقى كما هي...
  Future<bool> init({String? categoryId, int pageSize = 50}) async {
    try {
      final granted = await _image_service.initGallery();
      if (!granted) return false;
    } catch (e) {
      if (kDebugMode) print('GalleryProvider.init -> initGallery error: $e');
      return false;
    }

    _page = 0;
    images.clear();
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
      final newImages = await _image_service.loadImages(
        page: _page,
        size: size,
        categoryId: catId,
      );

      if (newImages.isNotEmpty) {
        images.addAll(newImages);
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
    images.clear();
    _selectionNotifier.value = {};
    _page = 0;
    hasMore = true;
    await loadMore(size: pageSize);
  }
}
