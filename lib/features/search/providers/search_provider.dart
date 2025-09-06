import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:smart_gallery_app/main.dart';
import '../../../core/network/api_client.dart';

class SearchProvider extends ChangeNotifier {
  final bool useServer;
  final ApiClient _api;

  SearchProvider({this.useServer = true}) : _api = ApiClient(baseUrl: baseUrl);

  // Current search results as string paths
  final List<String> _results = [];
  List<String> get results => List.unmodifiable(_results);

  // Local photos for fallback
  final List<String> _localPhotoPaths = [];
  void setLocalPhotoPaths(List<String> paths) {
    _localPhotoPaths
      ..clear()
      ..addAll(paths);
  }

  bool _loading = false;
  bool get isLoading => _loading;

  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  void clearResults() {
    _results.clear();
    _lastQuery = '';
    notifyListeners();
  }

  Future<void> searchByText(String query, {String? userId}) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }

    _loading = true;
    _lastQuery = query;
    notifyListeners();

    try {
      if (!useServer) {
        _performLocalTextSearch(query);
        return;
      }

      // call tags search endpoint which returns matches and images per tag
      final resp = await _api.searchTagsQuery(
        query: query,
        userId: userId,
        limit: 50,
      );

      _results.clear();

      if (resp == null) {
        // fallback to older searchByText if you have it
        final fallback = await _api.searchByText(
          userId: userId,
          query: query,
          topK: 20,
        );
        _processSearchResponse(fallback);
        return;
      }
      if (resp is Map && resp['matches'] is List) {
        final List<dynamic> matches = resp['matches'] as List<dynamic>;
        final Set<String> found = <String>{};

        for (final m in matches) {
          if (m is Map && m['images'] is List) {
            for (final img in (m['images'] as List)) {
              // img can be string (path) or map
              if (img is String) {
                found.add(img);
              } else if (img is Map) {
                // try common keys
                final p =
                    (img['phone_path'] ??
                    img['phone_paths'] ??
                    img['path'] ??
                    img['pc_path'] ??
                    img['thumbnail']);
                if (p is String && p.isNotEmpty) found.add(p);
                // if phone_paths is a list inside image object, take first string
                if (img['phone_paths'] is List) {
                  final list = (img['phone_paths'] as List)
                      .whereType<String>()
                      .toList();
                  if (list.isNotEmpty) found.addAll(list);
                }
              }
            }
          }
        }

        // put results (unique)
        _results.addAll(found);
        return;
      }

      // If unexpected format, fallback to generic processor
      _processSearchResponse(resp);
    } catch (e, st) {
      if (kDebugMode) debugPrint('searchByText error: $e\n$st');
      _results.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Search by uploaded image
  Future<void> searchByImage({
    required String userId,
    required File imageFile,
    int topK = 5,
    double minScore = 0.0,
  }) async {
    _loading = true;
    _lastQuery = 'Image: ${imageFile.path.split(Platform.pathSeparator).last}';
    notifyListeners();

    try {
      if (!useServer) {
        _performLocalImageSearch(imageFile);
        return;
      }

      final resp = await _api.searchByImage(
        userId: userId,
        file: imageFile,
        topK: topK,
        minScore: minScore,
      );
      _processSearchResponse(resp);
    } catch (e, st) {
      if (kDebugMode) debugPrint('searchByImage error: $e\n$st');
      _results.clear();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Process API response and extract paths
  void _processSearchResponse(dynamic resp) {
    _results.clear();

    if (resp == null) return;

    // Handle List<String> directly
    if (resp is List) {
      _results.addAll(resp.cast<String>());
      return;
    }

    // Handle Map with various keys
    if (resp is Map) {
      List<dynamic>? raw;

      // Try different possible keys
      for (String key in ['phone_paths', 'images', 'results', 'paths']) {
        if (resp[key] is List) {
          raw = resp[key] as List<dynamic>;
          break;
        }
      }

      if (raw != null) {
        for (final item in raw) {
          if (item is String) {
            _results.add(item);
          } else if (item is Map && item['phone_path'] is String) {
            _results.add(item['phone_path']);
          } else if (item is Map && item['path'] is String) {
            _results.add(item['path']);
          }
        }
        return;
      }
    }

    if (kDebugMode) {
      debugPrint('Unexpected response format: ${resp.runtimeType}');
    }
  }

  /// Local fallback for text search
  void _performLocalTextSearch(String query) {
    final lower = query.toLowerCase();
    final filtered = _localPhotoPaths.where((path) {
      return path.toLowerCase().contains(lower);
    }).toList();

    _results
      ..clear()
      ..addAll(filtered);
  }

  /// Local fallback for image search
  void _performLocalImageSearch(File imageFile) {
    // Very naive implementation - match by filename tokens
    final name = imageFile.path
        .split(Platform.pathSeparator)
        .last
        .toLowerCase();

    final filtered = _localPhotoPaths.where((path) {
      final pathName = path.split(Platform.pathSeparator).last.toLowerCase();
      return pathName.contains(name) || name.contains(pathName);
    }).toList();

    _results
      ..clear()
      ..addAll(filtered);
  }
}
