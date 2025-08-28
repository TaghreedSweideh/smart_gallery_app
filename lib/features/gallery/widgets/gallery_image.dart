// gallery_image.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryImage extends StatelessWidget {
  final AssetEntity? assetEntity;
  final String? assetPath;
  final Uint8List? imageData;
  final double borderRadius;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool isSelectable;
  final bool isSelected;
  final Widget? selectedIndicator;

  const GalleryImage({
    super.key,
    this.assetEntity,
    this.assetPath,
    this.imageData,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.isSelectable = false,
    this.isSelected = false,
    this.selectedIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // الصورة الأساسية
        _buildImageContent(),

        // مؤشر الاختيار إذا كان قابل للتحديد ومحدد
        if (isSelectable && isSelected) _buildSelectionOverlay(),
      ],
    );
  }

  Widget _buildImageContent() {
    if (assetEntity != null) {
      return FutureBuilder<Uint8List?>(
        future: assetEntity!.thumbnailDataWithSize(
          const ThumbnailSize(300, 300),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildPlaceholder();
          }
          if (!snapshot.hasData) {
            return _buildErrorPlaceholder();
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.memory(
              snapshot.data!,
              fit: fit,
              width: width,
              height: height,
            ),
          );
        },
      );
    }

    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(assetPath!, fit: fit, width: width, height: height),
      );
    }

    if (imageData != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(imageData!, fit: fit, width: width, height: height),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }

  Widget _buildSelectionOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child:
            selectedIndicator ??
            const Icon(Icons.check_circle, color: Colors.white, size: 30),
      ),
    );
  }
}
