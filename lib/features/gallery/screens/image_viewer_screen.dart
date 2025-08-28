import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:smart_gallery_app/core/theme/app_text_styles.dart';
import 'package:smart_gallery_app/widgets/general/dots_loader.dart';
import '../providers/gallery_provider.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.assets,
    required this.initialIndex,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isVisible = true; // لإخفاء وإظهار الـ AppBar و Bottom Bar

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  Future<void> _deleteCurrentImage(BuildContext context) async {
    bool confirm =
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
                // Handle indicator
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),

                // Icon
                Icon(Icons.delete_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),

                // Title
                Text(
                  "Delete Photo?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),

                // Message
                Text(
                  "This action cannot be undone",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Delete Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
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

    if (confirm == true) {
      final asset = widget.assets[_currentIndex];
      await PhotoManager.editor.deleteWithIds([asset.id]);
      if (mounted) {
        Provider.of<GalleryProvider>(context, listen: false).refresh();
        Navigator.pop(context);
      }
    }
  }

  String _formatDate(DateTime date) {
    String month = DateFormat.MMMM().format(date);
    String dayYear = DateFormat('dd, yyyy').format(date);
    String time = DateFormat('hh:mm a').format(date);
    return "$month $dayYear\n$time";
  }

  @override
  Widget build(BuildContext context) {
    DateTime date = widget.assets[_currentIndex].createDateTime;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: AnimatedSlide(
          duration: Duration(milliseconds: 300),
          offset: _isVisible ? Offset(0, 0) : Offset(0, -1),
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: _isVisible ? 1 : 0,
            child: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                _formatDate(date),
                textAlign: TextAlign.center,
                style: AppTextStyles.h4,
              ),
            ),
          ),
        ),
      ),

      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.assets.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return FutureBuilder<File?>(
            future: widget.assets[index].file,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: DotsLoader());
              }
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _isVisible = !_isVisible;
                  });
                },
                child: PhotoView(
                  imageProvider: FileImage(snapshot.data!),
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
        duration: Duration(milliseconds: 300),
        offset: _isVisible ? Offset(0, 0) : Offset(0, 1),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
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
