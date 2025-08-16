import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryImage extends StatelessWidget {
  final AssetEntity? assetEntity;
  final String? assetPath;
  final double borderRadius;
  final BoxFit fit;
  final double? width;

  const GalleryImage({
    super.key,
    this.assetEntity,
    this.assetPath,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    if (assetEntity != null) {
      return FutureBuilder<Uint8List?>(
        future: assetEntity!.thumbnailDataWithSize(
          const ThumbnailSize(300, 300),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(color: Colors.grey[200]);
          }
          if (!snapshot.hasData) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.memory(snapshot.data!, fit: fit, width: width),
          );
        },
      );
    }

    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(assetPath!, fit: fit),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
