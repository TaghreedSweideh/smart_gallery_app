import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'features/search/providers/search_provider.dart';

import 'core/services/sync_service.dart';
import 'core/network/api_client.dart';
import 'core/providers/sync_provider.dart';
import 'core/services/user_manager.dart';
import 'core/services/image_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/providers/home_provider.dart';
import 'features/gallery/providers/gallery_provider.dart';
import 'features/categories/providers/categories_provider.dart';
import 'features/splash/screens/splash_screen.dart';

const String baseUrl = 'http://192.168.0.70:8000';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? userId = await UserManager.getUserId();
  // print("saved user ID from server: $userId");
  if (userId == null) {
    final apiClient = ApiClient(baseUrl: baseUrl);
    String? newUserId = await apiClient.createUser();
    // print("successfully to fetch user ID from server: $newUserId");
    if (newUserId != null) {
      await UserManager.saveUserId(newUserId);
    } else {
      // print("Failed to fetch user ID from server");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final imageService = ImageService();
    final apiClient = ApiClient(baseUrl: baseUrl);
    final syncService = SyncService(apiClient: apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => HomeProvider(imageService),
        ),
        ChangeNotifierProvider<GalleryProvider>(
          create: (_) => GalleryProvider(imageService),
        ),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(
          create: (_) => SyncProvider(syncService, imageService),
        ),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            title: 'Smart Gallery',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
