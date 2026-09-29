import 'package:flutter/material.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/features/operations_stock_in/presentation/screens/stock_in_list_screen.dart';
import 'package:smartstock_admin/features/operations_stock_out/presentation/screens/stock_out_list_screen.dart';

class OperationsHubScreen extends StatelessWidget {
  const OperationsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Xuất Nhập Kho',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(46),
            child: Container(
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade700,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.move_to_inbox, size: 17),
                        SizedBox(width: 6),
                        Text('Nhập Kho'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.outbox, size: 17),
                        SizedBox(width: 6),
                        Text('Xuất Kho'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            StockInListScreen(embedded: true),
            StockOutListScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}
