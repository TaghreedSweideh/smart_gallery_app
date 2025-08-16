import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../gallery/models/photo_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = '';
  List<Photo> allPhotos = [];
  List<Photo> searchResults = [];
  bool isSearching = false;
  String searchMode = 'text';
  File? uploadedImageFile;
  Timer? _debounce;

  final List<String> popularTags = [
    'nature',
    'food',
    'people',
    'animals',
    'celebrations',
    'documents',
  ];

  @override
  void initState() {
    super.initState();
    _mockData();
  }

  void _mockData() {
    allPhotos = [
      Photo(
        id: '0',
        title: 'Sunset',
        category: 'nature',
        url: 'https://picsum.photos/200/300?random=1',
        tags: ['nature', 'sunset'],
      ),
      Photo(
        id: '1',
        title: 'Burger',
        category: 'food',
        url: 'https://picsum.photos/200/300?random=2',
        tags: ['food', 'burger'],
      ),
      Photo(
        id: '2',
        title: 'Party',
        category: 'celebrations',
        url: 'https://picsum.photos/200/300?random=3',
        tags: ['party', 'fun'],
      ),
    ];
  }

  void handleTextSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      searchQuery = query;
      isSearching = true;
    });

    if (query.trim().isEmpty) {
      setState(() {
        searchResults.clear();
        isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final lowerQuery = query.toLowerCase();
      final results = allPhotos.where((photo) {
        return photo.title.toLowerCase().contains(lowerQuery) ||
            photo.category.toLowerCase().contains(lowerQuery) ||
            (photo.tags?.any((tag) => tag.toLowerCase().contains(lowerQuery)) ??
                false);
      }).toList();

      setState(() {
        searchResults = results;
        isSearching = false;
      });
    });
  }

  Future<void> handleImageUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        uploadedImageFile = File(picked.path);
        isSearching = true;
      });

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        searchResults = allPhotos
            .where((photo) => photo.category == 'nature')
            .toList();
        isSearching = false;
      });
    }
  }

  void clearSearch() {
    setState(() {
      searchQuery = '';
      searchResults.clear();
      uploadedImageFile = null;
    });
  }

  void handleTagClick(String tag) {
    setState(() {
      searchQuery = tag;
      searchMode = 'text';
    });
    handleTextSearch(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search', style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildModeButtons(),
          if (searchMode == 'text')
            _buildSearchField()
          else
            _buildImageUploadButton(),
          if (uploadedImageFile != null) _buildUploadedImagePreview(),
          if (searchMode == 'text' && searchQuery.isEmpty) _buildPopularTags(),
          Expanded(child: _buildResults()),
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
          SizedBox(width: 3.w),
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
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blueAccent : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        setState(() {
          searchMode = mode;
          clearSearch();
        });
      },
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 25),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: clearSearch,
                )
              : null,
          hintText: 'Search by tags or description...',
          hintStyle: AppTextStyles.label,
          enabledBorder: _border(Colors.grey),
          focusedBorder: _border(Colors.blue, 2),
        ),
        cursorColor: Colors.blueAccent,
        onChanged: handleTextSearch,
        controller: TextEditingController(text: searchQuery),
      ),
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildImageUploadButton() {
    return Padding(
      padding: EdgeInsets.all(2.w),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.upload_file),
        label: const Text(
          'Upload an image to find similar photos',
          style: AppTextStyles.button,
        ),
        onPressed: handleImageUpload,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedImagePreview() {
    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Searching for similar images:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
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

  Widget _buildResults() {
    if (isSearching) return const Center(child: CircularProgressIndicator());
    if (searchResults.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: searchResults.length,
        itemBuilder: (_, index) {
          final photo = searchResults[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(photo.url, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
