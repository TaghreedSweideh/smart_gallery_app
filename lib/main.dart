import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'core/network/api_client.dart';
import 'core/services/user_manager.dart';
import 'features/home/providers/home_provider.dart';
import 'features/gallery/providers/gallery_provider.dart';
import 'features/categories/providers/categories_provider.dart';
import 'features/splash/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/services/image_service.dart';

void main() async {
  // //request id for if its the first time
  // WidgetsFlutterBinding.ensureInitialized();

  // // تحقق إذا كان لدينا User ID محفوظ
  // String? userId = await UserManager.getUserId();

  // if (userId == null) {
  //   // أول تشغيل للتطبيق
  //   final apiClient = ApiClient();
  //   String? newUserId = await apiClient.getUserId();

  //   if (newUserId != null) {
  //     await UserManager.saveUserId(newUserId);
  //   } else {
  //     // ممكن نعرض SnackBar عند فشل الاتصال
  //     print("Failed to fetch user ID from server");
  //   }
  // }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => HomeProvider(ImageService()),
        ),
        ChangeNotifierProvider<GalleryProvider>(
          create: (_) => GalleryProvider(ImageService()),
        ),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
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
