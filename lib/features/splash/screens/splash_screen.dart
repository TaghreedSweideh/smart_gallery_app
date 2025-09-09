// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../widgets/general/sync_progress.dart';
import '../../../widgets/general/dots_loader.dart';
import '../../../core/providers/sync_provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/screens/bottom_nav_bar.dart';
import '../../../widgets/general/logo.dart';
import '../../../features/gallery/providers/gallery_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  /// 🔹 طلب صلاحيات الصور/التخزين
  Future<bool> _ensureGalleryPermission() async {
    try {
      final statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.manageExternalStorage,
      ].request();

      bool granted = false;

      if (Platform.isAndroid) {
        if (statuses[Permission.manageExternalStorage]?.isGranted == true ||
            statuses[Permission.storage]?.isGranted == true) {
          granted = true;
        }
      }

      if (Platform.isIOS) {
        if (statuses[Permission.photos]?.isGranted == true) {
          granted = true;
        }
      }

      final pm = await PhotoManager.requestPermissionExtend();
      if (pm == PermissionState.authorized || pm == PermissionState.limited) {
        granted = true;
      }

      return granted;
    } catch (e, st) {
      debugPrint('_ensureGalleryPermission error: $e\n$st');
      return false;
    }
  }

  Future<void> _initializeApp() async {
    setState(() => _isInitializing = true);

    final prefs = await SharedPreferences.getInstance();
    final bool isFirstLaunch = prefs.getBool('first_launch') ?? true;

    try {
      final galleryProvider = Provider.of<GalleryProvider>(
        context,
        listen: false,
      );

      bool permissionOk = await _ensureGalleryPermission();

      if (!permissionOk) {
        final bool galleryReady = await galleryProvider.init();

        if (!galleryReady) {
          final action = await _showPermissionDialog();

          if (action == _PermissionAction.openSettings) {
            await openAppSettings();
            await Future.delayed(const Duration(seconds: 1));
            permissionOk = await _ensureGalleryPermission();
          } else if (action == _PermissionAction.retry) {
            permissionOk = await _ensureGalleryPermission();
            if (!permissionOk) {
              await galleryProvider.init();
            }
          } else {
            // skip
          }
        }
      } else {
        await galleryProvider.init();
      }

      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      try {
        await syncProvider.startIfNeeded();
      } catch (e, st) {
        debugPrint('SyncProvider.startIfNeeded ERROR: $e\n$st');
      }
    } catch (e, st) {
      debugPrint('Error initializing gallery provider: $e\n$st');
    }

    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isInitializing = false);

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
    final sync = Provider.of<SyncProvider>(context);
    final bool syncing = sync.syncing;
    final double progress = sync.progress;
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
              if (_isInitializing)
                syncing
                    ? SyncProgress(progress: progress)
                    : const DotsLoader(color: Colors.black54, dotSize: 6),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PermissionAction { retry, openSettings, skip }
