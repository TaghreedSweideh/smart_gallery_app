import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/general/dots_loader.dart';
import '../../categories/screens/categories_screen.dart';
import '../../categories/widgets/category_card.dart';
import '../../gallery/screens/gallery_screen.dart';
import '../../gallery/screens/image_viewer_screen.dart';
import '../../gallery/widgets/gallery_image.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/home_provider.dart';
import '../../../core/services/image_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeProvider(ImageService())..loadRecent(),
      child: Consumer<HomeProvider>(
        builder: (context, provider, _) {
          final recentPhotos = provider.recentPhotos;
          final loading = provider.loading;

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
                          MaterialPageRoute(builder: (_) => SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),

                // Recent Photos Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Photos', style: AppTextStyles.h3),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GalleryScreen(title: 'Gallery'),
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
                loading
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: DotsLoader(color: Colors.blueAccent),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final photo = recentPhotos[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ImageViewerScreen(
                                        assets: recentPhotos,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                child: GalleryImage(
                                  assetEntity: photo,
                                  borderRadius: 10,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }, childCount: recentPhotos.length),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2.w,
                                mainAxisSpacing: 2.w,
                              ),
                        ),
                      ),

                // Quick Access Categories Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quick Access', style: AppTextStyles.h3),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CategoriesScreen(),
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
                      final category = provider.quickCategories[index];
                      return CategoryCard(
                        category: category,
                        isCover: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GalleryScreen(
                                title: category.name,
                                categoryId: category.id,
                              ),
                            ),
                          );
                        },
                      );
                    }, childCount: provider.quickCategories.length),
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
        },
      ),
    );
  }
}
