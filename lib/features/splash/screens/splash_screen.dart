// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_gallery_app/widgets/general/dots_loader.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/screens/bottom_nav_bar.dart';
import '../../../widgets/general/logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _logoController.forward();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool("first_launch") ?? true;

    await Future.delayed(const Duration(seconds: 2));

    if (isFirstLaunch) {
      prefs.setBool("first_launch", false);
      final result = await PhotoManager.requestPermissionExtend();
      if (!result.isAuth) {
        PhotoManager.openSetting();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavBar()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavBar()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(width: 70.w, child: const Logo()),
              ),
            ),
            Text(
              'Smart Gallery',
              style: AppTextStyles.h2.copyWith(color: Colors.black87),
            ),
            SizedBox(height: 1.h),
            Text(
              'Organize your photos intelligently',
              style: AppTextStyles.h4.copyWith(color: Colors.black87),
            ),
            SizedBox(height: 2.h),
            const DotsLoader(color: Colors.black54, dotSize: 6),
          ],
        ),
      ),
    );
  }
}
