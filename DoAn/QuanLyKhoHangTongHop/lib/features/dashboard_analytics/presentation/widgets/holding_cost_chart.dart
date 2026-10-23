import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/analytics_models.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';

class HoldingCostChart extends StatefulWidget {
  final List<HoldingCostDataPoint> dataPoints;

  const HoldingCostChart({super.key, required this.dataPoints});

  @override
  State<HoldingCostChart> createState() => _HoldingCostChartState();
}

class _HoldingCostChartState extends State<HoldingCostChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi Phí Tồn Trữ & Dòng Tiền (Holding Cost)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'So sánh Chi phí lưu kho, Hao hụt/Hư hỏng và Doanh số bán ra',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(AppColors.primary, 'Doanh số bán ra'),
                _buildLegendItem(AppColors.warning, 'Chi phí lưu kho'),
                _buildLegendItem(AppColors.danger, 'Hao hụt & Hư hỏng'),
              ],
            ),
            const SizedBox(height: 18),

            // Bar Chart
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 250, // Triệu VND
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = widget.dataPoints[groupIndex];
                        return BarTooltipItem(
                          '${point.period}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'Doanh số: ${CurrencyFormatter.formatVND(point.revenue)}\n',
                              style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11),
                            ),
                            TextSpan(
                              text: 'Lưu kho: ${CurrencyFormatter.formatVND(point.storageCost)}\n',
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                            ),
                            TextSpan(
                              text: 'Hao hụt: ${CurrencyFormatter.formatVND(point.shrinkageCost)}',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= widget.dataPoints.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              widget.dataPoints[index].period,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
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
                  barGroups: List.generate(widget.dataPoints.length, (index) {
                    final point = widget.dataPoints[index];
                    final revTr = point.revenue / 1000000;
                    final storageTr = point.storageCost / 1000000;
                    final shrinkTr = point.shrinkageCost / 1000000;

                    return BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: revTr,
                          color: AppColors.primary,
                          width: 14,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: storageTr,
                          color: AppColors.warning,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: shrinkTr,
                          color: AppColors.danger,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
      ],
    );
  }
}
