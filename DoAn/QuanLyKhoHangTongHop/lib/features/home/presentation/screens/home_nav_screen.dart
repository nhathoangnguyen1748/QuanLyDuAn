import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard_analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../../../inventory_catalog/presentation/screens/product_list_screen.dart';
import '../../../operations_stock_in/presentation/screens/stock_in_list_screen.dart';
import '../../../operations_stock_out/presentation/screens/stock_out_list_screen.dart';
import '../../../cycle_counting/presentation/screens/cycle_count_list_screen.dart';
import '../../../reports_export/presentation/screens/reports_export_screen.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key});

  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  int _currentIndex = 1; // Default to Tab 1: Product List (Shopee Grid) for instant wow effect

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
        elevation: 6,
        indicatorColor: AppColors.shopeeBadgeBg,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics, color: AppColors.primary),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront, color: AppColors.primary),
            label: 'Sản Phẩm',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_shopping_cart_outlined),
            selectedIcon: Icon(Icons.add_shopping_cart, color: AppColors.primary),
            label: 'Nhập Kho',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary),
            label: 'Bán Hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check, color: AppColors.primary),
            label: 'Kiểm Kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: AppColors.primary),
            label: 'Báo Cáo',
          ),
        ],
      ),
    );
  }
}
