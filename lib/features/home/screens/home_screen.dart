import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/utils/assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/image_service.dart';
import '../../../widgets/general/dots_loader.dart';
import '../../categories/screens/categories_screen.dart';
import '../../categories/widgets/category_card.dart';
import '../../categories/models/category_model.dart';
import '../../gallery/screens/gallery_screen.dart';
import '../../gallery/widgets/gallery_image.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImageService _imageService = ImageService();
  List<AssetEntity> _recentPhotos = [];
  final List<Category> quickCategories = [
    Category(
      id: '1',
      name: 'Favorites',
      icon: '⭐',
      count: 12,
      thumbnail: AppAssets.book,
    ),
    Category(
      id: '2',
      name: 'Screenshots',
      icon: '📸',
      count: 20,
      thumbnail: AppAssets.bear,
    ),
    Category(
      id: '3',
      name: 'Selfies',
      icon: '🤳',
      count: 8,
      thumbnail: AppAssets.logo,
    ),
    Category(
      id: '4',
      name: 'Downloads',
      icon: '⬇️',
      count: 15,
      thumbnail: AppAssets.bear,
    ),
    Category(
      id: '5',
      name: 'Camera',
      icon: '📷',
      count: 30,
      thumbnail: AppAssets.book,
    ),
    Category(
      id: '6',
      name: 'Edited',
      icon: '✏️',
      count: 5,
      thumbnail: AppAssets.logo,
    ),
  ];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentPhotos();
  }

  Future<void> _loadRecentPhotos() async {
    final granted = await _imageService.initGallery();
    if (!granted) return;

    final recent = await _imageService.getRecentImages(count: 6);
    setState(() {
      _recentPhotos = recent;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Gallery', style: AppTextStyles.h2),
                Text('Welcome back!', style: AppTextStyles.label),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings,
                  size: 20.sp,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(onBack: () {}),
                    ),
                  );
                },
              ),
            ],
          ),
          // Recent Photos Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Photos', style: AppTextStyles.h3),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GalleryScreen(title: 'Gallery'),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent Photos Grid
          _loading
              ? SliverToBoxAdapter(
                  child: Center(child: DotsLoader(color: Colors.blueAccent)),
                )
              : SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final photo = _recentPhotos[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () {
                            // open photo detail
                          },
                          child: GalleryImage(
                            assetEntity: photo,
                            borderRadius: 10,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }, childCount: _recentPhotos.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2.w,
                      mainAxisSpacing: 2.w,
                    ),
                  ),
                ), // Quick Access Categories Title
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick Access', style: AppTextStyles.h3),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CategoriesScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Access Categories Grid
          SliverPadding(
            padding: EdgeInsets.only(right: 4.w, left: 4.w, bottom: 4.w),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = quickCategories[index];
                return CategoryCard(
                  category: category,
                  isCover: true, // first one is cover style
                  onTap: () {
                    // navigate to category gallery
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GalleryScreen(
                          title: category.name,
                          categoryId: category.id,
                        ),
                      ),
                    );
                  },
                );
              }, childCount: quickCategories.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
  }
}
