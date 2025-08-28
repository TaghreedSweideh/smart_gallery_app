import 'package:flutter/foundation.dart' hide Category;
import 'package:photo_manager/photo_manager.dart';
import '../../../core/services/image_service.dart';
import '../../categories/models/category_model.dart';
import '../../../core/utils/assets.dart';

class HomeProvider extends ChangeNotifier {
  final ImageService _imageService;

  HomeProvider(this._imageService);

  // Recent Photos
  List<AssetEntity> recentPhotos = [];
  bool loading = true;

  // Quick Access Categories
  final List<Category> quickCategories = [
    Category(
      id: '1',
      name: 'Favorites',
      icon: '⭐',
      count: 12,
      thumbnail: AppAssets.book,
    ),
    Category(
      id: '2',
      name: 'Screenshots',
      icon: '📸',
      count: 20,
      thumbnail: AppAssets.bear,
    ),
    Category(
      id: '3',
      name: 'Selfies',
      icon: '🤳',
      count: 8,
      thumbnail: AppAssets.logo,
    ),
    Category(
      id: '4',
      name: 'Downloads',
      icon: '⬇️',
      count: 15,
      thumbnail: AppAssets.bear,
    ),
    Category(
      id: '5',
      name: 'Camera',
      icon: '📷',
      count: 30,
      thumbnail: AppAssets.book,
    ),
    Category(
      id: '6',
      name: 'Edited',
      icon: '✏️',
      count: 5,
      thumbnail: AppAssets.logo,
    ),
  ];

  /// Load recent photos
  Future<void> loadRecent({int count = 6}) async {
    loading = true;
    notifyListeners();

    try {
      final granted = await _imageService.initGallery();
      if (!granted) return;

      final recent = await _imageService.getRecentImages(count: count);
      recentPhotos = recent;
    } catch (e) {
      if (kDebugMode) print('HomeProvider.loadRecent error: $e');
      recentPhotos = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
