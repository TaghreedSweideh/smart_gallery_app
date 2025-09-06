// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../../../widgets/general/dots_loader.dart';
import '../../../core/services/user_manager.dart';
import '../../gallery/screens/gallery_screen.dart';
import '../providers/categories_provider.dart';
import '../widgets/category_card.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  Future<void> _deleteSelectedCategories(BuildContext context) async {
    final provider = Provider.of<CategoriesProvider>(context, listen: false);

    if (provider.selectedCategoryIds.isEmpty) return;

    bool confirm =
        await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_delete, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Delete ${provider.selectedCount} categor${provider.selectedCount > 1 ? 'ies' : 'y'}?",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "All photos in these categories will be deleted",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!confirm) return;

    // call provider (your provider returns summary map)
    final summary = await provider.deleteSelectedCategories(
      removeFilesFromDisk: true,
    );
    final deleted = (summary['deletedCategories'] as List).cast<String>();
    final failed = (summary['failed'] as Map<String, String>);

    String message;
    if (deleted.isNotEmpty && failed.isEmpty) {
      message =
          'Deleted ${deleted.length} categor${deleted.length > 1 ? 'ies' : 'y'}.';
    } else if (deleted.isNotEmpty && failed.isNotEmpty) {
      message =
          'Deleted ${deleted.length} categories, failed ${failed.length}.';
    } else {
      message = 'Failed to delete selected categories.';
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (failed.isNotEmpty) {
      final details = failed.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Deletion details'),
          content: SingleChildScrollView(child: Text(details)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = CategoriesProvider();
        UserManager.getUserId().then((id) {
          if (id != null) {
            provider.fetchCategories(id);
          }
        });
        return provider;
      },
      child: Consumer<CategoriesProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: ValueListenableBuilder<Set<String>>(
                valueListenable: provider.selectionNotifier,
                builder: (context, selection, _) {
                  return Text(
                    selection.isEmpty
                        ? 'Categories'
                        : "${selection.length} selected",
                    style: TextStyle(
                      fontSize: selection.isEmpty ? 18 : 16,
                      fontWeight: selection.isEmpty
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                },
              ),
              centerTitle: true,
              actions: [
                ValueListenableBuilder<Set<String>>(
                  valueListenable: provider.selectionNotifier,
                  builder: (context, selection, _) {
                    if (selection.isEmpty) return const SizedBox();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.select_all,
                            color: Colors.blue,
                          ),
                          onPressed: provider.selectAll,
                          tooltip: 'Select all',
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.blue),
                          onPressed: provider.clearSelection,
                          tooltip: 'Clear selection',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            bottomNavigationBar: ValueListenableBuilder<Set<String>>(
              valueListenable: provider.selectionNotifier,
              builder: (context, selection, _) {
                if (selection.isEmpty) return const SizedBox.shrink();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: SafeArea(
                    top: false,
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteSelectedCategories(context),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        "Delete ${selection.length} categor${selection.length > 1 ? 'ies' : 'y'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                );
              },
            ),
            body: provider.isLoading
                ? const Center(child: DotsLoader())
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.all(4.w),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final category = provider.categories[index];

                            return ValueListenableBuilder<Set<String>>(
                              valueListenable: provider.selectionNotifier,
                              builder: (context, selection, _) {
                                final isSelected = selection.contains(
                                  category.id,
                                );
                                final isSelecting = selection.isNotEmpty;

                                return CategoryCard(
                                  category: category,
                                  isCover: true,
                                  isSelectable: isSelecting,
                                  isSelected: isSelected,
                                  onTap: () {
                                    if (isSelecting) {
                                      provider.toggleSelection(category.id);
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => GalleryScreen(
                                            title: category.name,
                                            categoryId: category.id,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  onLongPress: () {
                                    provider.toggleSelection(category.id);
                                  },
                                );
                              },
                            );
                          }, childCount: provider.categories.length),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 2.w,
                                mainAxisSpacing: 4.w,
                                childAspectRatio: 0.33.w,
                              ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
