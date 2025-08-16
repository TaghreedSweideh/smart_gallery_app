import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/services/image_service.dart';
import '../../../widgets/general/dots_loader.dart';

class GalleryScreen extends StatefulWidget {
  final String? categoryId; // null means all photos
  final String title;

  const GalleryScreen({super.key, this.categoryId, required this.title});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImageService _imageService = ImageService();
  final List<AssetEntity> _images = [];
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _initGallery();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initGallery() async {
    bool granted = await _imageService.initGallery();
    if (granted) {
      _loadMoreImages();
    }
  }

  Future<void> _loadMoreImages() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final newImages = await _imageService.loadImages(
      page: _currentPage,
      size: 50,
      categoryId: widget.categoryId,
    );

    setState(() {
      _images.addAll(newImages);
      _isLoading = false;
      _currentPage++;
      if (newImages.isEmpty) _hasMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreImages();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _images.isEmpty && !_isLoading
          ? const Center(child: Text("No images found"))
          : GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: _images.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _images.length) {
                  return const Center(
                    child: DotsLoader(color: Colors.blueAccent),
                  );
                }
                return FutureBuilder<Uint8List?>(
                  future: _images[index].thumbnailDataWithSize(
                    const ThumbnailSize(200, 200),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(color: Colors.grey.shade200);
                    }
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  },
                );
              },
            ),
    );
  }
}
