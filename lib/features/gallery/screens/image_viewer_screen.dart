// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:smart_gallery_app/core/theme/app_text_styles.dart';
import 'package:smart_gallery_app/widgets/general/dots_loader.dart';
import '../../../core/services/user_manager.dart';
import '../providers/gallery_provider.dart';

class ImageViewerScreen extends StatefulWidget {
  /// items can be AssetEntity or String (file path)
  final List<dynamic> items;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isVisible = true;

  /// Local mutable copy of items so we can remove safely
  late List<dynamic> _items;

  @override
  void initState() {
    super.initState();
    // make a modifiable copy of provided items
    _items = List<dynamic>.from(widget.items);
    _currentIndex = widget.initialIndex.clamp(
      0,
      _items.isNotEmpty ? _items.length - 1 : 0,
    );
    _pageController = PageController(initialPage: _currentIndex);
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final res =
        await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.white,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          builder: (ctx) => Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(Icons.delete_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Delete Photo?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "This action cannot be undone",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
    return res;
  }

  Future<void> _deleteCurrentImage(BuildContext context) async {
    if (_items.isEmpty) return;

    final confirm = await _confirmDelete(context);
    if (!confirm) return;

    final provider = Provider.of<GalleryProvider>(context, listen: false);
    final item = _items[_currentIndex];

    // ---------- Case: local asset ----------
    if (item is AssetEntity) {
      try {
        await PhotoManager.editor.deleteWithIds([item.id]);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete photo')),
          );
        }
        return;
      }

      // Update provider local gallery (refresh)
      if (mounted) {
        try {
          await provider.refresh();
        } catch (_) {}
      }

      // remove from local list and move to next or pop
      if (!mounted) return;
      setState(() {
        _items.removeAt(_currentIndex);
        if (_items.isEmpty) {
          Navigator.pop(context);
          return;
        } else {
          if (_currentIndex >= _items.length) {
            _currentIndex = _items.length - 1;
          }
          // jump/animate to new currentIndex
          _pageController.jumpToPage(_currentIndex);
        }
      });
      return;
    }

    // ---------- Case: server phone path (String) ----------
    if (item is String) {
      // normalize path (remove file:// if present)
      var phonePath = item;
      if (phonePath.startsWith('file://')) {
        phonePath = phonePath.replaceFirst('file://', '');
      }

      String? userId;
      try {
        userId = await UserManager.getUserId();
      } catch (_) {
        userId = null;
      }

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No user id available')));
        }
        return;
      }

      bool ok = false;
      try {
        // provider.deleteSingleServerImage should delete server-side and update provider._categoryImages
        await provider.deleteSingleServerImage(
          userId: userId,
          phonePath: phonePath,
        );
        ok = true;
      } catch (e) {
        ok = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete file on server')),
          );
        }
      }

      if (!ok) return;

      // Update viewer list locally: remove and navigate to next
      if (!mounted) return;
      setState(() {
        _items.removeAt(_currentIndex);

        if (_items.isEmpty) {
          Navigator.pop(context);
          return;
        } else {
          if (_currentIndex >= _items.length) {
            _currentIndex = _items.length - 1;
          }
          _pageController.jumpToPage(_currentIndex);
        }
      });

      return;
    }

    // Unknown type => ignore
  }

  String _formatDate(DateTime date) {
    final month = DateFormat.MMMM().format(date);
    final dayYear = DateFormat('dd, yyyy').format(date);
    final time = DateFormat('hh:mm a').format(date);
    return "$month $dayYear\n$time";
  }

  Future<File?> _fileForItem(dynamic item) async {
    if (item is AssetEntity) {
      try {
        return await item.file;
      } catch (_) {
        return null;
      }
    } else if (item is String) {
      try {
        final f = File(item);
        if (f.existsSync()) return f;
        return null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // defensive: if items empty, pop
    if (_items.isEmpty) {
      Future.microtask(() => Navigator.pop(context));
      return const SizedBox.shrink();
    }

    final dynamic currentItem = _items[_currentIndex];
    DateTime? createDate;
    if (currentItem is AssetEntity) {
      createDate = currentItem.createDateTime;
    } else {
      try {
        final f = File(currentItem as String);
        if (f.existsSync()) createDate = f.lastModifiedSync();
      } catch (_) {
        createDate = null;
      }
    }

    final title = createDate != null ? _formatDate(createDate) : '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: _isVisible ? Offset.zero : const Offset(0, -1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isVisible ? 1 : 0,
            child: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.h4,
              ),
            ),
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _items.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final item = _items[index];
          return FutureBuilder<File?>(
            future: _fileForItem(item),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: DotsLoader(color: Colors.lightBlueAccent),
                );
              }
              final file = snapshot.data;
              if (file == null) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 56,
                  ),
                );
              }
              return GestureDetector(
                onTap: () => setState(() => _isVisible = !_isVisible),
                child: PhotoView(
                  imageProvider: FileImage(file),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  initialScale: PhotoViewComputedScale.contained,
                  gestureDetectorBehavior: HitTestBehavior.translucent,
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isVisible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isVisible ? 1 : 0,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => _deleteCurrentImage(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
