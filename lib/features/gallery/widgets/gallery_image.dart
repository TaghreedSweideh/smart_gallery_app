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
    // put ClipRRect once so both image and overlay are clipped consistently
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          // image area (fills available tile)
          Positioned.fill(child: _buildImageContent()),

          // selection overlay
          if (isSelectable && isSelected)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child:
                      selectedIndicator ??
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 30,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    // All image widgets are wrapped into a SizedBox.expand (via Positioned.fill above),
    // so we can simply return the image and let BoxFit.cover crop it to the tile.
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

          return Image.memory(
            snapshot.data!,
            fit: fit,
            width: width ?? double.infinity,
            height: height ?? double.infinity,
            gaplessPlayback: true,
          );
        },
      );
    }

    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        fit: fit,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        gaplessPlayback: true,
      );
    }

    if (imageData != null) {
      return Image.memory(
        imageData!,
        fit: fit,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        gaplessPlayback: true,
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(color: Colors.grey[200], alignment: Alignment.center);
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
