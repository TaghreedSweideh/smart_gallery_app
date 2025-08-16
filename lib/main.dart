import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'features/splash/screens/splash_screen.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Smart Gallery',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
          // initialRoute: '/',
          // routes: {
          //   '/': (context) => const SplashScreen(),
          //   '/home': (context) => const HomeScreen(
          //     photos: [],
          //     categories: [],
          //     onNavigate: (String screen, Category? category) {},
          //   ),
          // },
        );
      },
    );
  }
}
