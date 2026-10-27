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
  int _currentIndex = 1; // Default to Tab 1: Product List

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
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
            );
          }),
        ),
        child: NavigationBar(
          height: 62,
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          elevation: 6,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: AppColors.shopeeBadgeBg,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, size: 21),
              selectedIcon: Icon(Icons.analytics, color: AppColors.primary, size: 21),
              label: 'Thống kê',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined, size: 21),
              selectedIcon: Icon(Icons.storefront, color: AppColors.primary, size: 21),
              label: 'Sản phẩm',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_shopping_cart_outlined, size: 21),
              selectedIcon: Icon(Icons.add_shopping_cart, color: AppColors.primary, size: 21),
              label: 'Nhập kho',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined, size: 21),
              selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary, size: 21),
              label: 'Bán hàng',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined, size: 21),
              selectedIcon: Icon(Icons.fact_check, color: AppColors.primary, size: 21),
              label: 'Kiểm kê',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined, size: 21),
              selectedIcon: Icon(Icons.description, color: AppColors.primary, size: 21),
              label: 'Báo cáo',
            ),
          ],
        ),
      ),
    );
  }
}
