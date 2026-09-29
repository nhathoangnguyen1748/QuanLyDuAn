import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/analytics_models.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';

class CategoryDonutChart extends StatefulWidget {
  final List<CategoryDistributionItem> categories;

  const CategoryDonutChart({super.key, required this.categories});

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(child: Text('Không có dữ liệu ngành hàng'));
    }

    final totalValue = widget.categories.fold(0.0, (s, c) => s + c.totalValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cơ Cấu Danh Mục & Ngành Hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 2),
                Text(
                  'Tỷ trọng giá trị vốn lưu kho theo từng ngành hàng',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Donut Chart
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      sections: List.generate(widget.categories.length, (i) {
                        final cat = widget.categories[i];
                        final isTouched = i == _touchedIndex;
                        final double fontSize = isTouched ? 14.0 : 11.0;
                        final double radius = isTouched ? 60.0 : 50.0;
                        final color = Color(cat.colorHex);

                        return PieChartSectionData(
                          color: color,
                          value: cat.percentage > 0 ? cat.percentage : 1.0,
                          title: '${cat.percentage.toStringAsFixed(0)}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),

                  // Trung tâm của Donut hiển thị danh mục đang chọn hoặc Tổng giá trị
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _touchedIndex >= 0 && _touchedIndex < widget.categories.length
                            ? widget.categories[_touchedIndex].categoryName.split(' ')[0]
                            : 'TỔNG VỐN',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _touchedIndex >= 0 && _touchedIndex < widget.categories.length
                            ? CurrencyFormatter.formatCompactVND(widget.categories[_touchedIndex].totalValue)
                            : CurrencyFormatter.formatCompactVND(totalValue),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách các danh mục chi tiết
            Column(
              children: widget.categories.map((cat) {
                final color = Color(cat.colorHex);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.categoryName,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${CurrencyFormatter.formatNumber(cat.totalStockUnits)} sản phẩm',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatCompactVND(cat.totalValue),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${cat.percentage.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
