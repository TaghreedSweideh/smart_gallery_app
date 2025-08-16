import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:smart_gallery_app/features/gallery/screens/gallery_screen.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/assets.dart';
import '../models/category_model.dart';
import '../widgets/category_card.dart';

class CategoriesScreen extends StatelessWidget {
  final List<Category> categories = [
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
    Category(
      id: '7',
      name: 'Duplicates',
      icon: '🐾',
      count: 100,
      thumbnail: AppAssets.logo,
    ),
    Category(
      id: '8',
      name: 'Ducuments',
      icon: '📄',
      count: 100,
      thumbnail: AppAssets.bear,
    ),
    Category(
      id: '9',
      name: 'Night photos',
      icon: '🌃',
      count: 10,
      thumbnail: AppAssets.logo,
    ),
  ];

  CategoriesScreen({super.key});

  // void handleCategoryClick(Category category) {
  //   if (category.id == 'duplicates') {
  //     onNavigate('duplicates');
  //   } else if (category.id == 'blurred') {
  //     onNavigate('blurred');
  //   } else {
  //     onNavigate('category-gallery', category: category);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            floating: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Categories', style: AppTextStyles.h2),
                Text(
                  'Organize your photos by type',
                  style: AppTextStyles.label,
                ),
              ],
            ),
            // actions: [
            //   IconButton(
            //     icon: Icon(
            //       Icons.settings,
            //       size: 20.sp,
            //       color: Colors.grey[600],
            //     ),
            //     onPressed: () {
            //       Navigator.of(context).push(
            //         MaterialPageRoute(
            //           builder: (context) => SettingsScreen(onBack: () {}),
            //         ),
            //       );
            //     },
            //   ),
            // ],
          ),

          // Categories Grid
          SliverPadding(
            padding: EdgeInsets.all(4.w),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = categories[index];
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
              }, childCount: categories.length),
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
