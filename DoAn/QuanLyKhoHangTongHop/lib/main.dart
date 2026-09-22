import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/storage/hive_storage_service.dart';
import 'features/home/presentation/screens/home_nav_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo cơ sở dữ liệu Hive offline và Seed Data
  await HiveStorageService.instance.init();

  runApp(
    const ProviderScope(
      child: SmartStockApp(),
    ),
  );
}

class SmartStockApp extends StatelessWidget {
  const SmartStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartStock Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const HomeNavScreen(),
    );
  }
}
