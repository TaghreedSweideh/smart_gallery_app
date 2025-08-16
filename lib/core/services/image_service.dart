import 'package:photo_manager/photo_manager.dart';

class ImageService {
  AssetPathEntity? _allPhotosAlbum;
  final Map<String, AssetPathEntity> _albumsCache = {};

  Future<bool> initGallery() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (!ps.isAuth) {
      PhotoManager.openSetting();
      return false;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );

    if (albums.isNotEmpty) {
      _allPhotosAlbum = albums.first;

      // Cache all albums for quick lookup
      for (var album in albums) {
        _albumsCache[album.id] = album;
      }
      return true;
    }
    return false;
  }

  Future<List<AssetEntity>> loadImages({
    required int page,
    int size = 50,
    String? categoryId,
  }) async {
    if (_allPhotosAlbum == null) {
      throw Exception("Gallery not initialized. Call initGallery() first.");
    }

    AssetPathEntity album;
    if (categoryId != null) {
      // Try to find cached album, otherwise fetch from system
      if (_albumsCache.containsKey(categoryId)) {
        album = _albumsCache[categoryId]!;
      } else {
        final albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          hasAll: true,
        );
        try {
          album = albums.firstWhere((a) => a.id == categoryId);
          _albumsCache[categoryId] = album; // cache it
        } catch (e) {
          throw Exception("Album with id $categoryId not found.");
        }
      }
    } else {
      album = _allPhotosAlbum!;
    }

    return await album.getAssetListPaged(page: page, size: size);
  }

  /// Get the most recent images from the "All Photos" album
  Future<List<AssetEntity>> getRecentImages({int count = 6}) async {
    if (_allPhotosAlbum == null) {
      throw Exception("Gallery not initialized. Call initGallery() first.");
    }

    return await _allPhotosAlbum!.getAssetListPaged(page: 0, size: count);
  }
}
