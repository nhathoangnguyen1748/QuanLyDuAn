import 'package:flutter/material.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/features/dashboard_analytics/presentation/screens/analytics_dashboard_screen.dart';
import 'package:smartstock_admin/features/inventory_catalog/presentation/screens/product_list_screen.dart';
import 'package:smartstock_admin/features/cycle_counting/presentation/screens/cycle_count_list_screen.dart';
import 'package:smartstock_admin/features/reports_export/presentation/screens/reports_export_screen.dart';
import 'operations_hub_screen.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key});

  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AnalyticsDashboardScreen(),
    ProductListScreen(),
    OperationsHubScreen(),
    CycleCountListScreen(),
    ReportsExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              );
            }
            return TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics, color: AppColors.primary),
              label: 'Tổng Quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
              label: 'Tồn Kho',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_vert_circle_outlined),
              selectedIcon: Icon(Icons.swap_vert_circle, color: AppColors.primary),
              label: 'Xuất Nhập',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check, color: AppColors.primary),
              label: 'Kiểm Kê',
            ),
            NavigationDestination(
              icon: Icon(Icons.print_outlined),
              selectedIcon: Icon(Icons.print, color: AppColors.primary),
              label: 'Báo Cáo',
            ),
          ],
        ),
      ),
    );
  }
}
