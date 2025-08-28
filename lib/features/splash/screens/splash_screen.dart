// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:smart_gallery_app/widgets/general/dots_loader.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/screens/bottom_nav_bar.dart';
import '../../../widgets/general/logo.dart';
import '../../../features/gallery/providers/gallery_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _dotsController;

  bool _isInitializing = true;

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
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _logoController.forward();

    // Delay real initialization until after first frame so context & providers exist
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  Future<void> _initializeApp() async {
    setState(() => _isInitializing = true);

    final prefs = await SharedPreferences.getInstance();
    final bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

    // Try initializing gallery provider (which should request permissions internally)
    try {
      final galleryProvider = Provider.of<GalleryProvider>(
        context,
        listen: false,
      );

      // call init() on the provider; make sure your GalleryProvider exposes a method that returns bool
      // (true if init succeeded / permission granted), otherwise adapt below
      final bool galleryReady = await galleryProvider.init();

      if (!galleryReady) {
        // permission denied or init failed; prompt user
        final action = await _showPermissionDialog();
        if (action == _PermissionAction.openSettings) {
          PhotoManager.openSetting();
          // wait a bit for user to possibly grant permission
          await Future.delayed(const Duration(seconds: 1));
          final retry = await galleryProvider.init();
          if (!retry) {
            // still not granted; continue but show limited UX
            debugPrint('Gallery permission not granted after settings.');
          }
        } else if (action == _PermissionAction.retry) {
          final retry = await galleryProvider.init();
          if (!retry) {
            debugPrint('User retried but permission still denied.');
          }
        } else {
          // user chose skip; continue without gallery
        }
      }
    } catch (e) {
      debugPrint('Error initializing gallery provider: $e');
      // we continue to splash fallback
    }

    // mark first launch if needed (we mark it regardless so that the stored flag is up-to-date)
    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
    }

    // keep splash visible for a small minimum time for the animation (so it doesn't flash)
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isInitializing = false);

    // Finally navigate to main app (BottomNavBar). Use replacement so splash is gone.
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const BottomNavBar()));
  }

  Future<_PermissionAction?> _showPermissionDialog() {
    return showDialog<_PermissionAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'This app needs access to your photos to show the gallery. '
            'You can open settings to grant access or retry permission request.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_PermissionAction.skip),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_PermissionAction.retry),
              child: const Text('Retry'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_PermissionAction.openSettings),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
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
      body: SafeArea(
        child: Center(
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
              SizedBox(height: 2.h),
              Text(
                'Smart Gallery',
                style: AppTextStyles.h2.copyWith(color: Colors.black87),
              ),
              SizedBox(height: 0.6.h),
              Text(
                'Organize your photos intelligently',
                style: AppTextStyles.h4.copyWith(color: Colors.black87),
              ),
              SizedBox(height: 2.h),
              // show loader while init is running
              _isInitializing
                  ? const DotsLoader(color: Colors.black54, dotSize: 6)
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PermissionAction { retry, openSettings, skip }
