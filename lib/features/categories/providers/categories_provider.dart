// features/categories/providers/category_provider.dart
import 'package:flutter/foundation.dart' hide Category;
import '../../../core/network/api_client.dart';
import '../../../core/services/user_manager.dart';
import '../../../main.dart';
import '../models/category_model.dart';

class CategoriesProvider extends ChangeNotifier {
  final List<Category> _categories = [];

  List<Category> get categories => List.unmodifiable(_categories);

  // حالة الاختيار
  final ValueNotifier<Set<String>> _selectionNotifier =
      ValueNotifier<Set<String>>({});
  Set<String> get selectedCategoryIds => _selectionNotifier.value;
  bool get isSelecting => _selectionNotifier.value.isNotEmpty;
  int get selectedCount => _selectionNotifier.value.length;

  ValueNotifier<Set<String>> get selectionNotifier => _selectionNotifier;

  void toggleSelection(String categoryId) {
    final newSelection = Set<String>.from(_selectionNotifier.value);
    if (newSelection.contains(categoryId)) {
      newSelection.remove(categoryId);
    } else {
      newSelection.add(categoryId);
    }
    _selectionNotifier.value = newSelection;
  }

  void clearSelection() {
    _selectionNotifier.value = {};
  }

  void selectAll() {
    _selectionNotifier.value = Set<String>.from(_categories.map((e) => e.id));
  }

  bool _loading = false;
  bool get isLoading => _loading;

  Future<void> fetchCategories(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final api = ApiClient(baseUrl: baseUrl);
      final data = await api.getUserCategories(userId: userId);
      if (data != null) {
        _categories
          ..clear()
          ..addAll(data.map((json) => Category.fromJson(json)));
      }
    } catch (e) {
      if (kDebugMode) print("fetchCategories error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Delete selected categories (server-side images by category AND remove category locally on success).
  /// Returns a summary map: { "deletedCategories": [ids], "failed": { categoryId: errorMessage } }
  Future<Map<String, dynamic>> deleteSelectedCategories({
    bool removeFilesFromDisk = false,
  }) async {
    final result = <String, dynamic>{
      'deletedCategories': <String>[],
      'failed': <String, String>{},
    };

    final selected = Set<String>.from(_selectionNotifier.value);
    if (selected.isEmpty) return result;

    // get user id
    String? userId;
    try {
      userId = await UserManager.getUserId();
    } catch (_) {
      userId = null;
    }

    if (userId == null || userId.isEmpty) {
      // mark all as failed
      for (final id in selected) {
        (result['failed'] as Map<String, String>)[id] = 'No user id available';
      }
      return result;
    }

    final api = ApiClient(baseUrl: baseUrl);

    // iterate categories selected and call API to delete images in category
    for (final catIdStr in selected) {
      int? catId;
      try {
        catId = int.tryParse(catIdStr);
      } catch (_) {
        catId = null;
      }

      if (catId == null) {
        (result['failed'] as Map<String, String>)[catIdStr] =
            'Invalid category id';
        continue;
      }

      try {
        final resp = await api.deleteImagesInCategory(
          userId: userId,
          categoryId: catId,
          removeFile: removeFilesFromDisk,
        );

        if (resp == null) {
          (result['failed'] as Map<String, String>)[catIdStr] =
              'Network / server error';
          continue;
        }

        // Evaluate server response:
        // server returns {"success": bool, "deleted": [...], "failed": {...}}
        final success = resp['success'] == true;
        final deletedList = (resp['deleted'] is List)
            ? List.from(resp['deleted']).map((e) => e.toString()).toList()
            : <String>[];

        if (success || deletedList.isNotEmpty) {
          // treat as success -> remove category locally
          _categories.removeWhere((c) => c.id == catIdStr);
          (result['deletedCategories'] as List<String>).add(catIdStr);
        } else {
          // server didn't delete anything -> record failure details if any
          final failedMap = resp['failed'];
          final reason = (failedMap != null)
              ? failedMap.toString()
              : 'no deleted items';
          (result['failed'] as Map<String, String>)[catIdStr] = reason;
        }
      } catch (e) {
        (result['failed'] as Map<String, String>)[catIdStr] = 'Exception: $e';
      }
    }

    // clear selection for categories that were deleted
    final newSel = Set<String>.from(_selectionNotifier.value);
    for (final id in (result['deletedCategories'] as List<String>)) {
      newSel.remove(id);
    }
    _selectionNotifier.value = newSel;

    notifyListeners();
    return result;
  }
}
