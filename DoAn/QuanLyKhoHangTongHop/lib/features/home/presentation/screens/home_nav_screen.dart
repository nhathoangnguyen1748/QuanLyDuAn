import 'package:flutter/material.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/features/dashboard_analytics/presentation/screens/analytics_dashboard_screen.dart';
import 'package:smartstock_admin/features/inventory_catalog/presentation/screens/product_list_screen.dart';
import 'package:smartstock_admin/features/operations_stock_in/presentation/screens/stock_in_list_screen.dart';
import 'package:smartstock_admin/features/operations_stock_out/presentation/screens/stock_out_list_screen.dart';
import 'package:smartstock_admin/features/cycle_counting/presentation/screens/cycle_count_list_screen.dart';
import 'package:smartstock_admin/features/reports_export/presentation/screens/reports_export_screen.dart';

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
    StockInListScreen(),
    StockOutListScreen(),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
            label: 'Tồn Kho',
          ),
          NavigationDestination(
            icon: Icon(Icons.move_to_inbox_outlined),
            selectedIcon: Icon(Icons.move_to_inbox, color: AppColors.primary),
            label: 'Nhập Kho',
          ),
          NavigationDestination(
            icon: Icon(Icons.outbox_outlined),
            selectedIcon: Icon(Icons.outbox, color: AppColors.primary),
            label: 'Xuất Kho',
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
    );
  }
}
