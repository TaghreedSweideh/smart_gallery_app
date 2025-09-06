// features/home/providers/home_provider.dart
import 'package:flutter/foundation.dart' hide Category;
import 'package:photo_manager/photo_manager.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/user_manager.dart';
import '../../categories/models/category_model.dart';
import 'package:smart_gallery_app/main.dart';
import '../../../core/network/api_client.dart';

class HomeProvider extends ChangeNotifier {
  final ImageService _imageService;
  final ApiClient _api;

  HomeProvider(this._imageService) : _api = ApiClient(baseUrl: baseUrl);

  // Recent Photos
  List<AssetEntity> recentPhotos = [];
  bool loading = true;

  // Quick Access Categories (initial defaults can remain as placeholders until loaded)
  final List<Category> quickCategories = [];

  /// Load recent photos and quick categories (both)
  Future<void> loadRecent({int count = 6}) async {
    loading = true;
    notifyListeners();

    try {
      final granted = await _imageService.initGallery();
      if (!granted) {
        // if permission denied, set empty
        recentPhotos = [];
      } else {
        final recent = await _imageService.getRecentImages(count: count);
        recentPhotos = recent;
      }
    } catch (e) {
      if (kDebugMode) print('HomeProvider.loadRecent error: $e');
      recentPhotos = [];
    } finally {
      // Try load quick categories (don't block UI)
      _loadQuickCategoriesSafely();
      loading = false;
      notifyListeners();
    }
  }

  // ----- Quick categories logic -----

  /// Public method to explicitly refresh quick categories if needed
  Future<void> refreshQuickCategories() async {
    await _loadQuickCategories();
  }

  /// internal wrapper so we call but don't leak exceptions
  Future<void> _loadQuickCategoriesSafely() async {
    try {
      await _loadQuickCategories();
    } catch (e) {
      if (kDebugMode) debugPrint('Quick categories load failed: $e');
    }
  }

  /// Load categories from backend and set top 6 for quick access.
  /// If userId not provided, the ApiClient might still return a generic list.
  Future<void> _loadQuickCategories() async {
    String? userId = await UserManager.getUserId();
    try {
      // call your existing API client method (similar to CategoriesProvider.fetchCategories)
      final data = await _api.getUserCategories(
        userId: userId!,
      ); // adjust endpoint expectations
      if (data == null || data.isEmpty) {
        // nothing from backend — keep defaults
        return;
      }

      // Map JSON -> Category model
      final List<Category> fetched = data.map((json) {
        try {
          return Category.fromJson(json);
        } catch (e) {
          // fallback: build minimal Category if mapping fails
          return Category(
            id: (json['id']?.toString() ?? ''),
            name: (json['name']?.toString() ?? 'Unknown'),
            icon: json['icon']?.toString() ?? '📁',
            count: json['num_images'] is int
                ? (json['num_images'] as int)
                : int.tryParse(json['num_images']?.toString() ?? '') ?? 0,
            thumbnail: json['thumbnail']?.toString(),
          );
        }
      }).toList();

      // Choose top 6 by count (num_images / count) if available, otherwise take first 6.
      fetched.sort((a, b) => (b.count).compareTo(a.count));
      final selected = fetched.take(6).toList();

      // If any selected item lacks a local thumbnail, you may want to keep its server thumbnail (pc_path)
      // For now we just set quickCategories to these selected categories:
      quickCategories
        ..clear()
        ..addAll(selected);

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('HomeProvider._loadQuickCategories error: $e');
      // keep existing quickCategories (defaults) if error
    }
  }
}
