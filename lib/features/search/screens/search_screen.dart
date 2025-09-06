// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/general/dots_loader.dart';
import '../../../core/services/user_manager.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../main.dart';
import '../../search/providers/search_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = '';
  File? uploadedImageFile;
  Timer? _debounce;
  String searchMode = 'text'; // 'text' or 'image'
  final List<String> popularTags = ['Sky', 'Building', 'Car', 'Cat', 'Pizza'];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text != searchQuery) {
        handleTextSearch(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void handleTextSearch(String query) {
    setState(() => searchQuery = query);

    final provider = Provider.of<SearchProvider>(context, listen: false);

    if (query.trim().isEmpty) {
      provider.clearResults();
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      provider.searchByText(query);
    });
  }

  void handleTagClick(String tag) {
    setState(() {
      searchQuery = tag;
      searchMode = 'text';
      _searchController.text = tag; // update controller so UI updates
    });

    final provider = Provider.of<SearchProvider>(context, listen: false);
    provider.searchByText(tag);
  }

  Future<void> handleImageUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      uploadedImageFile = File(picked.path);
    });

    final provider = Provider.of<SearchProvider>(context, listen: false);
    final userId = await UserManager.getUserId();

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user ID available')));
      return;
    }

    await provider.searchByImage(userId: userId, imageFile: uploadedImageFile!);
  }

  void clearSearch() {
    setState(() {
      searchQuery = '';
      uploadedImageFile = null;
    });
    _searchController.clear();
    final provider = Provider.of<SearchProvider>(context, listen: false);
    provider.clearResults();
  }

  Widget _buildResultImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    if (baseUrl.isNotEmpty) {
      final normalizedPath = imagePath.replaceAll('\\', '/');
      final url = baseUrl.endsWith('/')
          ? '$baseUrl$normalizedPath'
          : '$baseUrl/$normalizedPath';

      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    }

    return _buildErrorPlaceholder();
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchProvider>(context);
    final isSearching = provider.isLoading;
    final searchResults = provider.results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          if (searchResults.isNotEmpty || provider.lastQuery.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear), onPressed: clearSearch),
        ],
      ),
      body: Column(
        children: [
          _buildModeButtons(),
          _buildSearchInput(),
          if (uploadedImageFile != null) _buildUploadedImagePreview(),
          Expanded(
            child: isSearching
                ? const Center(child: DotsLoader(color: Colors.blueAccent))
                : _buildSearchResults(searchResults),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButtons() {
    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton('Text Search', Icons.search, 'text'),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildModeButton('Image Search', Icons.camera_alt, 'image'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, IconData icon, String mode) {
    final isActive = searchMode == mode;
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: AppTextStyles.label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blueAccent : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
      ),
      onPressed: () {
        setState(() {
          searchMode = mode;
          clearSearch();
        });
      },
    );
  }

  Widget _buildSearchInput() {
    switch (searchMode) {
      case 'text':
        return _buildSearchField();
      case 'image':
        return _buildImageUploadButton();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 25),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: clearSearch,
                )
              : null,
          hintText: 'Search photos by text...',
          hintStyle: AppTextStyles.label,
          enabledBorder: _inputBorder(Colors.grey),
          focusedBorder: _inputBorder(Colors.blue, 2),
        ),
        cursorColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildImageUploadButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.upload_file, color: Colors.blueAccent),
        label: Text(
          'Upload image to find similar photos',
          style: AppTextStyles.button.copyWith(color: Colors.blueAccent),
        ),
        onPressed: handleImageUpload,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildUploadedImagePreview() {
    return Padding(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Searching for similar images:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.w),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              uploadedImageFile!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<String> results) {
    if (results.isEmpty) {
      final provider = Provider.of<SearchProvider>(context);
      // show "no results" if user has typed something before
      if (provider.lastQuery.isNotEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No results found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }
      // show popular tags ONLY if we're in text search mode (and no query yet)
      if (searchMode == 'text') {
        return _buildPopularTags();
      }
      return const SizedBox.shrink();
    }
    return GridView.builder(
      padding: EdgeInsets.all(3.w),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: results.length,
      itemBuilder: (_, index) {
        final imagePath = results[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildResultImage(imagePath),
        );
      },
    );
  }

  OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildPopularTags() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.w, horizontal: 3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Popular Tags', style: AppTextStyles.h4),
          SizedBox(height: 3.w),
          Wrap(
            spacing: 1.w,
            runSpacing: 1.w,
            children: popularTags
                .map(
                  (tag) => ActionChip(
                    elevation: 1,
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.w,
                    ),
                    label: Text(
                      tag,
                      style: AppTextStyles.label.copyWith(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: const Color(0xFFEFF6FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.transparent),
                    ),
                    onPressed: () => handleTagClick(tag),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
