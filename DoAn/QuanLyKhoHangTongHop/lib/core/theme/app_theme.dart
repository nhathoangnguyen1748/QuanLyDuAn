import 'package:flutter/material.dart';

/// Design System & Color Tokens chuẩn hóa cho hệ thống Quản Lý Kho Hàng
class AppTheme {
  AppTheme._();

  // Bảng màu ngữ nghĩa công nghiệp (Industrial WMS Tokens)
  static const Color primarySeed = Color(0xFF0F4C81);     // Classic Warehouse Blue
  static const Color primaryDark = Color(0xFF0A3357);
  static const Color secondaryColor = Color(0xFF0D9488);  // Deep Teal
  static const Color surfaceColor = Color(0xFFF8FAFC);    // Slate Surface 50
  static const Color scaffoldBackground = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBorderColor = Color(0xFFE2E8F0); // Slate 200

  // Màu trạng thái nghiệp vụ kho
  static const Color successColor = Color(0xFF10B981);    // Tồn an toàn / Nhập kho
  static const Color warningColor = Color(0xFFF59E0B);    // Tồn cảnh báo
  static const Color dangerColor = Color(0xFFEF4444);     // Hết hàng / Lỗi
  static const Color infoColor = Color(0xFF3B82F6);       // Điều chuyển kho

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      primary: primarySeed,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      surface: surfaceColor,
      onSurface: const Color(0xFF0F172A),
      error: dangerColor,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: _buildTextTheme(const Color(0xFF0F172A)),
      appBarTheme: const AppBarTheme(
        backgroundColor: primarySeed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primarySeed, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySeed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
        ),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => const Icon(Icons.arrow_back_ios_new, size: 20),
      ),
    );
  }

  /// Khắc phục hoàn toàn lỗi cắt chân chữ có dấu Tiếng Việt (ệ, ự, ỹ, g, p, y)
  /// Đặt `height` trong khoảng 1.3 - 1.45 để glyph không bị tràn bounding-box
  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.32,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.38,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: const Color(0xFF475569),
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.3,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.25,
      ),
    );
  }
}
