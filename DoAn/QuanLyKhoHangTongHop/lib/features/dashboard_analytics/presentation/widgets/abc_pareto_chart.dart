import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/analytics_models.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';

class ABCParetoChart extends StatefulWidget {
  final ParetoAnalysisResult paretoResult;

  const ABCParetoChart({super.key, required this.paretoResult});

  @override
  State<ABCParetoChart> createState() => _ABCParetoChartState();
}

class _ABCParetoChartState extends State<ABCParetoChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.paretoResult.items.take(8).toList(); // Hiển thị Top 8 SKU tiêu biểu
    if (items.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu phân tích'));
    }

    final double maxRevenue = items.fold(0.0, (max, item) => item.revenueValue > max ? item.revenueValue : max);
    final double maxY = maxRevenue > 0 ? (maxRevenue / 1000000) * 1.2 : 100; // Triệu VND

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề & Thông số Pareto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phân Tích ABC (Nguyên Lý Pareto 80/20)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tỷ trọng doanh thu theo từng nhóm hàng hóa',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '80 / 15 / 5 Rule',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Nhãn tóm tắt 3 nhóm A, B, C
            Row(
              children: [
                Expanded(
                  child: _buildGroupIndicator(
                    group: 'Nhóm A',
                    skuCount: widget.paretoResult.groupACount,
                    share: widget.paretoResult.groupAValueShare,
                    color: AppColors.abcGroupA,
                    desc: 'Quan trọng nhất (80% giá trị)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGroupIndicator(
                    group: 'Nhóm B',
                    skuCount: widget.paretoResult.groupBCount,
                    share: widget.paretoResult.groupBValueShare,
                    color: AppColors.abcGroupB,
                    desc: 'Trung bình (15% giá trị)',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGroupIndicator(
                    group: 'Nhóm C',
                    skuCount: widget.paretoResult.groupCCount,
                    share: widget.paretoResult.groupCValueShare,
                    color: AppColors.abcGroupC,
                    desc: 'Phổ thông (5% giá trị)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Biểu đồ cột Bar Chart thể hiện Doanh thu theo SKU
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = items[groupIndex];
                        return BarTooltipItem(
                          '${item.name}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'Doanh số: ${CurrencyFormatter.formatVND(item.revenueValue)}\n',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            TextSpan(
                              text: 'Tích lũy: ${item.cumulativePercent.toStringAsFixed(1)}% (Nhóm ${item.group})',
                              style: TextStyle(
                                color: item.group == 'A' ? Colors.greenAccent : (item.group == 'B' ? Colors.amberAccent : Colors.redAccent),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        if (response?.spot != null) {
                          _touchedIndex = response!.spot!.touchedBarGroupIndex;
                        } else {
                          _touchedIndex = -1;
                        }
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= items.length) return const SizedBox.shrink();
                          final item = items[index];
                          final isGroupA = item.group == 'A';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              'P${index + 1}\n[${item.group}]',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isGroupA ? FontWeight.bold : FontWeight.normal,
                                color: item.group == 'A' ? AppColors.abcGroupA : (item.group == 'B' ? AppColors.abcGroupB : AppColors.abcGroupC),
                              ),
                            ),
                          );
                        },
                        reservedSize: 36,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}Tr',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(items.length, (index) {
                    final item = items[index];
                    final isTouched = _touchedIndex == index;
                    final revenueTr = item.revenueValue / 1000000;
                    Color barColor = AppColors.abcGroupC;
                    if (item.group == 'A') barColor = AppColors.abcGroupA;
                    if (item.group == 'B') barColor = AppColors.abcGroupB;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: revenueTr,
                          color: isTouched ? barColor.withValues(alpha: 0.8) : barColor,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Chú giải chi tiết mặt hàng
            Text(
              'Chú giải: P1...P8 là top mặt hàng có doanh thu luân chuyển cao nhất. Đường phân loại ABC tự động căn chỉnh ngưỡng kiểm soát tồn kho.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupIndicator({
    required String group,
    required int skuCount,
    required double share,
    required Color color,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(group, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${share.toStringAsFixed(1)}% giá trị',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            '$skuCount mặt hàng',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}
