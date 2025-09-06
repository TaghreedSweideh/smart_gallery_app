// features/gallery/screens/gallery_screen.dart
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_text_styles.dart';
import 'image_viewer_screen.dart';
import '../../../widgets/general/dots_loader.dart';
import '../providers/gallery_provider.dart';
import '../widgets/gallery_image.dart';
import '../../../core/services/user_manager.dart';

class GalleryScreen extends StatefulWidget {
  final String? categoryId;
  final String title;

  const GalleryScreen({super.key, this.categoryId, required this.title});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, Uint8List?> _imageCache = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<GalleryProvider>(context, listen: false);

      // If categoryId is numeric -> treat as server category: do not init local gallery
      if (widget.categoryId != null) {
        final catId = int.tryParse(widget.categoryId!);
        if (catId != null) {
          // server category: clear local images (prevent showing previous local results)
          provider.clearLocalImagesAndSelection();

          final userId = await UserManager.getUserId();
          if (userId != null && userId.isNotEmpty) {
            try {
              await provider.fetchCategoryImages(
                userId: userId,
                categoryId: catId,
              );
            } catch (e, st) {
              debugPrint('GalleryScreen: fetchCategoryImages error: $e\n$st');
            }
          } else {
            debugPrint('GalleryScreen: no userId found in SharedPreferences');
          }

          // still add scroll listener (though server list won't page)
          _scrollController.addListener(_onScroll);
          return;
        }
      }

      // otherwise: normal local init and paging
      await provider.init(categoryId: widget.categoryId);
      _scrollController.addListener(_onScroll);
    });
  }

  void _onScroll() {
    final provider = Provider.of<GalleryProvider>(context, listen: false);
    if (!provider.loading &&
        provider.hasMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      provider.loadMore();
    }
  }

  Future<void> _deleteSelectedImages() async {
    final provider = Provider.of<GalleryProvider>(context, listen: false);

    if (provider.selectedImageIds.isEmpty) return;

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
                const Icon(Icons.delete_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Delete ${provider.selectedCount} photo${provider.selectedCount > 1 ? 's' : ''}?",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This action cannot be undone",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
                          backgroundColor: Colors.grey,
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

    if (confirm == true) {
      // unified deletion: provider will handle asset ids, local file deletions
      // and server-side deletion if possible (ids present)
      String? userId = await UserManager.getUserId();
      await provider.deleteSelectedImages(userId: userId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deletting ...')));
      }
    }
  }

  Future<Uint8List?> _loadImage(AssetEntity asset) async {
    final String id = asset.id;

    if (_imageCache.containsKey(id)) {
      return _imageCache[id];
    }

    final data = await asset.thumbnailDataWithSize(
      const ThumbnailSize(250, 250),
    );
    _imageCache[id] = data;
    return data;
  }

  void _openFileViewer(
    BuildContext ctx,
    List<dynamic> items,
    int initialIndex,
  ) {
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) =>
            ImageViewerScreen(items: items, initialIndex: initialIndex),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _imageCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GalleryProvider>(context);
    final images = provider.images;
    final serverPaths = provider.categoryImages;

    final showingServer = serverPaths.isNotEmpty;
    final isFetchingServer = provider.isFetchingCategory;

    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<Set<String>>(
          valueListenable: provider.selectionNotifier,
          builder: (context, selection, _) {
            return Text(
              selection.isEmpty ? widget.title : "${selection.length} selected",
              style: AppTextStyles.h2,
            );
          },
        ),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<Set<String>>(
            valueListenable: provider.selectionNotifier,
            builder: (context, selection, _) {
              if (selection.isEmpty) return const SizedBox();

              return IconButton(
                icon: const Icon(Icons.clear, color: Colors.blue),
                onPressed: provider.clearSelection,
                tooltip: 'Clear selection',
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SafeArea(
              top: false,
              child: ElevatedButton.icon(
                onPressed: _deleteSelectedImages,
                icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                label: Text(
                  "Delete ${selection.length} photo${selection.length > 1 ? 's' : ''}",
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
      body: isFetchingServer
          ? const Center(child: DotsLoader(color: Colors.blueAccent))
          : (!showingServer && images.isEmpty && !provider.loading)
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No images found",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1.5,
                crossAxisSpacing: 1.5,
              ),
              itemCount:
                  (showingServer ? serverPaths.length : images.length) +
                  (provider.hasMore && !showingServer ? 1 : 0),
              itemBuilder: (context, index) {
                if (!showingServer && index >= images.length) {
                  return const Center(
                    child: DotsLoader(color: Colors.blueAccent),
                  );
                }

                // SERVER CELL
                if (showingServer) {
                  final raw = serverPaths[index];
                  // if stored as "id:path" extract path for file access
                  final path = raw.contains(':')
                      ? raw.split(':').sublist(1).join(':')
                      : raw;
                  final file = File(path);
                  final exists = file.existsSync();

                  return ValueListenableBuilder<Set<String>>(
                    valueListenable: provider.selectionNotifier,
                    builder: (context, selection, _) {
                      final isSelected = selection.contains(raw);
                      final isSelecting = selection.isNotEmpty;

                      return GestureDetector(
                        onTap: () {
                          if (isSelecting) {
                            provider.toggleSelection(raw);
                          } else {
                            // open viewer with serverPaths (list of Strings)
                            _openFileViewer(context, serverPaths, index);
                          }
                        },
                        onLongPress: () {
                          provider.toggleSelection(raw);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: exists
                                    ? Image.file(
                                        file,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) =>
                                            Container(color: Colors.grey[200]),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                              ),
                              if (isSelecting && isSelected)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                // LOCAL AssetEntity CELL
                final asset = images[index];

                return ValueListenableBuilder<Set<String>>(
                  valueListenable: provider.selectionNotifier,
                  builder: (context, selection, _) {
                    final isSelected = selection.contains(asset.id);

                    return GestureDetector(
                      onTap: () {
                        if (selection.isNotEmpty) {
                          provider.toggleSelection(asset.id);
                        } else {
                          // open viewer with local AssetEntity list (passed as dynamic list)
                          final items = List<dynamic>.from(images);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImageViewerScreen(
                                items: items,
                                initialIndex: index,
                              ),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        provider.toggleSelection(asset.id);
                      },
                      child: FutureBuilder<Uint8List?>(
                        future: _loadImage(asset),
                        builder: (context, snapshot) {
                          return GalleryImage(
                            assetEntity: asset,
                            imageData: snapshot.data,
                            isSelectable: selection.isNotEmpty,
                            isSelected: isSelected,
                            fit: BoxFit.cover,
                            borderRadius: 0,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
