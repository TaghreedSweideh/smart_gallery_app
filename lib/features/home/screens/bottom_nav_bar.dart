import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:smart_gallery_app/features/search/screens/search_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../../core/theme/app_text_styles.dart';
import 'home_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;
  void _onItemTapped(int index) => setState(() => _currentIndex = index);

  final List<Widget> _screens = [
    const HomeScreen(),
    CategoriesScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        padding: EdgeInsets.symmetric(vertical: 0.8.h, horizontal: 2.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(index: 0, icon: Icons.home_outlined, label: 'Home'),
            _buildNavItem(
              index: 1,
              icon: Icons.folder_copy_outlined,
              label: 'Categories',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.search_outlined,
              label: 'Search',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,

    required String label,
  }) {
    final isActive = _currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(2.w),
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(2.w),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: isActive ? Colors.blueAccent : Colors.grey,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isActive ? Colors.blueAccent : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
