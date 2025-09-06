import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class ApiClient {
  final Dio dio;

  ApiClient({required String baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  Future<String?> createUser() async {
    try {
      debugPrint('ApiClient.createUser: POST /user');
      final response = await dio.post('/user', data: {});
      final status = response.statusCode ?? 0;
      debugPrint(
        'ApiClient.createUser: response status=$status data=${response.data}',
      );
      if (status != 200 && status != 201) return null;
      final data = response.data;
      if (data is Map && data.containsKey('id')) return data['id']?.toString();
      if (data is String) {
        final s = data.trim();
        if (s.startsWith('"') && s.endsWith('"')) {
          return jsonDecode(s) as String?;
        }
        if (s.isNotEmpty) return s;
      }
      final decoded = jsonDecode(response.toString());
      if (decoded is Map && decoded.containsKey('id')) {
        return decoded['id']?.toString();
      }
      return null;
    } on DioException catch (e) {
      debugPrint(
        'ApiClient.createUser DioError: ${e.message} ${e.response?.data}',
      );
      return null;
    } catch (e) {
      debugPrint('ApiClient.createUser error: $e');
      return null;
    }
  }

  /// Upload images to POST /images/{user_id}
  /// phonePaths must be same length and order as files (use '' for unknown).
  Future<List<Map<String, dynamic>>?> uploadImages({
    required String userId,
    required List<File> files,
    List<String>? phonePaths,
    void Function(double progress)? onProgress,
  }) async {
    debugPrint('ApiClient.uploadImages: userId=$userId files=${files.length}');
    try {
      final multipartFiles = <MultipartFile>[];
      for (var f in files) {
        final fileName = p.basename(f.path);
        multipartFiles.add(
          await MultipartFile.fromFile(f.path, filename: fileName),
        );
      }

      // Ensure phonePaths length matches files length
      final phone = (phonePaths ?? List.filled(files.length, ''))
          .take(files.length)
          .toList();
      if (phone.length < files.length) {
        phone.addAll(List.filled(files.length - phone.length, ''));
      }

      debugPrint(
        'ApiClient.uploadImages: phonePaths sample=${phone.isNotEmpty ? phone[0] : "none"}',
      );

      final form = FormData.fromMap({
        'phone_paths': phone,
        'files': multipartFiles,
      });

      final response = await dio.post(
        '/images/$userId',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (int sent, int totalBytes) {
          if (totalBytes > 0 && onProgress != null) {
            onProgress(sent / totalBytes);
          }
        },
      );

      debugPrint(
        'ApiClient.uploadImages: response status=${response.statusCode}',
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        debugPrint(
          'ApiClient.uploadImages failed: ${response.statusCode} ${response.data}',
        );
        return null;
      }

      // Handle both List and { success, images }
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map.containsKey('images') && map['images'] is List) {
          return (map['images'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
      }

      return null;
    } on DioException catch (e) {
      debugPrint(
        'ApiClient.uploadImages DioError: ${e.message} ${e.response?.data}',
      );
      return null;
    } catch (e) {
      debugPrint('ApiClient.uploadImages error: $e');
      return null;
    }
  }

  /// GET /users/{user_id}/categories
  Future<List<Map<String, dynamic>>?> getUserCategories({
    required String userId,
  }) async {
    try {
      final resp = await dio.get('/users/$userId/categories');
      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        if (resp.data is Map && resp.data.containsKey('categories')) {
          final raw = resp.data['categories'];
          if (raw is List) return raw.cast<Map<String, dynamic>>();
        }
        // fallback if server returns list directly
        if (resp.data is List) {
          return (resp.data as List).cast<Map<String, dynamic>>();
        }
      }
      debugPrint('getUserCategories failed: ${resp.statusCode} ${resp.data}');
      return null;
    } on DioException catch (e) {
      debugPrint('getUserCategories DioError: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('getUserCategories error: $e');
      return null;
    }
  }

  // core/network/api_client.dart
  Future<List<String>?> getCategoryImages({
    required String userId,
    required int categoryId,
  }) async {
    try {
      final resp = await dio.get(
        '/users/$userId/categories/$categoryId/phone_paths',
      );
      debugPrint(
        'getCategoryImages: resp.status=${resp.statusCode} data=${resp.data.runtimeType}',
      );

      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        final d = resp.data;

        // 1) If server returns top-level map with key phone_paths
        if (d is Map) {
          if (d.containsKey('phone_paths')) {
            final raw = d['phone_paths'];
            if (raw is List) {
              return raw
                  .map((e) => e?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          }

          // 2) server returns { "images": [ { "phone_paths": [...] } ] }
          if (d.containsKey('images')) {
            final imgs = d['images'];
            if (imgs is List) {
              // try to extract strings if it's a flat list of strings
              if (imgs.isNotEmpty && imgs.first is String) {
                return imgs.cast<String>();
              }
              // else if each image is map with phone_paths list or phone_path string
              final List<String> collected = [];
              for (final item in imgs) {
                if (item is Map) {
                  if (item.containsKey('phone_paths')) {
                    final pp = item['phone_paths'];
                    if (pp is List) {
                      collected.addAll(
                        pp
                            .map((e) => e?.toString() ?? '')
                            .where((s) => s.isNotEmpty),
                      );
                    }
                  } else if (item.containsKey('phone_path')) {
                    final pp = item['phone_path'];
                    if (pp != null) collected.add(pp.toString());
                  }
                }
              }
              if (collected.isNotEmpty) return collected;
            }
          }
        }

        // 3) If server returned a top-level list of strings
        if (d is List) {
          return d
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }

      debugPrint(
        'getCategoryImages: unexpected response: ${resp.statusCode} ${resp.data}',
      );
      return null;
    } on DioException catch (e) {
      debugPrint(
        'getCategoryImages DioError: ${e.message} respData=${e.response?.data}',
      );
      return null;
    } catch (e) {
      debugPrint('getCategoryImages error: $e');
      return null;
    }
  }

  /// Search for similar images by uploading a file
  /// Returns list of phone_paths strings or null on error
  Future<List<String>?> searchSimilar({
    required String userId,
    required File file,
    int topK = 5,
    double minScore = 0,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final fileName = p.basename(file.path);
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      final form = FormData.fromMap({'file': multipartFile});

      final response = await dio.post(
        '/search_similar/$userId',
        data: form,
        queryParameters: {'top_k': topK, 'min_score': minScore},
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        if (kDebugMode) {
          debugPrint('searchSimilar failed: $status ${response.data}');
        }
        return null;
      }

      return _extractStringList(response.data, 'phone_paths');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'searchSimilar DioException: ${e.message} ${e.response?.data}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('searchSimilar error: $e');
      return null;
    }
  }

  /// GET /tags/search?q=...&user_id=...
  /// Returns decoded response (Map) or null on error.
  Future<dynamic> searchTagsQuery({
    required String query,
    String? userId,
    int limit = 20,
  }) async {
    try {
      final params = {'q': query, 'limit': limit};
      if (userId != null && userId.isNotEmpty) {
        params['user_id'] = int.tryParse(userId)!;
      }

      final response = await dio.get('/tags/search', queryParameters: params);

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        if (kDebugMode) {
          debugPrint('searchTagsQuery failed: $status ${response.data}');
        }
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'searchTagsQuery DioException: ${e.message} ${e.response?.data}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('searchTagsQuery error: $e');
      return null;
    }
  }

  /// Search by text/tags
  /// Returns list of phone_paths or full photo objects
  Future<dynamic> searchByText({
    String? userId,
    required String query,
    int topK = 10,
  }) async {
    try {
      final endpoint = userId != null ? '/search_text/$userId' : '/search_text';

      final response = await dio.get(
        endpoint,
        queryParameters: {'query': query, 'top_k': topK},
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        if (kDebugMode) {
          debugPrint('searchByText failed: $status ${response.data}');
        }
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'searchByText DioException: ${e.message} ${e.response?.data}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('searchByText error: $e');
      return null;
    }
  }

  /// Search by tags specifically
  /// Returns list of phone_paths or full photo objects
  Future<dynamic> searchByTags({
    String? userId,
    required List<String> tags,
    int topK = 10,
    bool matchAll = false, // true = AND operation, false = OR operation
  }) async {
    try {
      final endpoint = userId != null ? '/search_tags/$userId' : '/search_tags';

      final response = await dio.post(
        endpoint,
        data: {'tags': tags, 'match_all': matchAll, 'top_k': topK},
        options: Options(contentType: 'application/json'),
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        if (kDebugMode) {
          debugPrint('searchByTags failed: $status ${response.data}');
        }
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'searchByTags DioException: ${e.message} ${e.response?.data}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('searchByTags error: $e');
      return null;
    }
  }

  /// Search by image (searchSimilar for consistency)
  Future<dynamic> searchByImage({
    required String userId,
    required File file,
    int topK = 5,
    double minScore = 0.0,
  }) async {
    return await searchSimilar(
      userId: userId,
      file: file,
      topK: topK,
      minScore: minScore,
    );
  }

  /// Helper method to extract string list from response
  List<String>? _extractStringList(dynamic data, String key) {
    if (data is Map && data.containsKey(key)) {
      final raw = data[key];
      if (raw is List) {
        return raw.cast<String>();
      }
    }

    //might return list directly
    if (data is List) {
      return data.cast<String>();
    }

    // try decode if it's a string
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map && decoded.containsKey(key)) {
          final raw = decoded[key];
          if (raw is List) return raw.cast<String>();
        }
        if (decoded is List) return decoded.cast<String>();
      } catch (_) {}
    }

    return null;
  }

  /// Delete images by phone paths for a user (bulk)
  /// POST /users/{user_id}/images/by-phone/bulk
  /// Body: { "phone_paths": ["p1","p2"], "remove_file": true }
  Future<Map<String, dynamic>?> deleteImagesByPaths({
    required String? userId,
    required List<String> phonePaths,
    bool removeFile = true,
  }) async {
    try {
      final payload = {'phone_paths': phonePaths, 'remove_file': removeFile};

      final response = await dio.post(
        '/users/$userId/images/by-phone/bulk',
        data: payload,
        options: Options(contentType: 'application/json'),
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        if (kDebugMode) {
          debugPrint(
            'deleteImagesByPhonePaths failed: $status ${response.data}',
          );
        }
        return null;
      }

      // Expect map-like response
      if (response.data is Map) return Map<String, dynamic>.from(response.data);
      // try decode if it's a string
      try {
        if (response.toString().isNotEmpty) {
          final decoded = jsonDecode(response.toString());
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'deleteImagesByPhonePaths DioException: ${e.message} ${e.response?.data}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('deleteImagesByPhonePaths error: $e');
      return null;
    }
  }

  /// Delete all images in a category for a user.
  /// Calls DELETE /users/{user_id}/categories/{category_id}/images?remove_file={true|false}
  /// Returns MapString, dynamic? parsed response (null on network error).
  Future<Map<String, dynamic>?> deleteImagesInCategory({
    required String userId,
    required int categoryId,
    bool removeFile = false,
  }) async {
    try {
      final response = await dio.delete(
        '/users/$userId/categories/$categoryId/images',
        queryParameters: {'remove_file': removeFile},
        options: Options(contentType: 'application/json'),
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        if (kDebugMode) {
          debugPrint('deleteImagesInCategory failed: $status ${response.data}');
        }
        return null;
      }

      if (response.data is Map) return Map<String, dynamic>.from(response.data);

      // try to decode string body
      try {
        final decoded = jsonDecode(response.toString());
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}

      return null;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'deleteImagesInCategory DioException: ${e.message} ${e.response?.data}',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('deleteImagesInCategory error: $e');
      return null;
    }
  }
}
