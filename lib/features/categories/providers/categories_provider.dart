// features/categories/providers/category_provider.dart
import 'package:flutter/foundation.dart' hide Category;
import '../../../core/utils/assets.dart';
import '../models/category_model.dart';

class CategoriesProvider extends ChangeNotifier {
  final List<Category> _categories = [
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
    Category(
      id: '7',
      name: 'Duplicates',
      icon: '🐾',
      count: 100,
      thumbnail: AppAssets.logo,
    ),
    Category(
      id: '8',
      name: 'Documents',
      icon: '📄',
      count: 100,
      thumbnail: AppAssets.bear,
    ),
    Category(
      id: '9',
      name: 'Night photos',
      icon: '🌃',
      count: 10,
      thumbnail: AppAssets.logo,
    ),
  ];

  List<Category> get categories => _categories;

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

  Future<void> deleteSelectedCategories() async {
    if (_selectionNotifier.value.isEmpty) return;

    try {
      // هنا سيتم حذف المجلدات من التخزين
      // await _deleteCategoriesFromStorage(_selectionNotifier.value);

      // إزالة المجلدات المحددة من القائمة
      _categories.removeWhere(
        (category) => _selectionNotifier.value.contains(category.id),
      );

      // مسح حالة الاختيار
      _selectionNotifier.value = {};

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error deleting categories: $e');
      rethrow;
    }
  }

  // دالة محاكاة لحذف المجلدات من التخزين
  Future<void> _deleteCategoriesFromStorage(Set<String> categoryIds) async {
    // TODO: تنفيذ عملية الحذف الفعلية من التخزين
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
