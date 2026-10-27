import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/inventory/screens/inventory_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuanLyKhoApp());
}

class QuanLyKhoApp extends StatelessWidget {
  const QuanLyKhoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Kho Hàng Tổng Hợp',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Giới hạn TextScaler từ 0.85 đến 1.15 để ngăn vỡ khung hình khi máy phóng to font chữ
        final mediaQueryData = MediaQuery.of(context);
        final clampedTextScaler = mediaQueryData.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.15,
        );

        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: clampedTextScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const InventoryDashboardScreen(),
    );
  }
}
