import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/analytics_models.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';

class ITRTrendChart extends StatefulWidget {
  final List<ITRDataPoint> trendData;

  const ITRTrendChart({super.key, required this.trendData});

  @override
  State<ITRTrendChart> createState() => _ITRTrendChartState();
}

class _ITRTrendChartState extends State<ITRTrendChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.trendData.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final latestITR = widget.trendData.last.itr;
    final daysPerTurnover = (365 / latestITR).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hệ Số Vòng Quay Tồn Kho (ITR)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ITR = Giá vốn hàng bán (COGS) / Tồn kho bình quân',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '${latestITR.toStringAsFixed(1)} vòng/năm',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Banner giải thích tốc độ giải phóng hàng
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tốc độ giải phóng hàng hiện tại: ~$daysPerTurnover ngày/vòng quay (Chuẩn tối ưu ngành bán lẻ/kho sỉ: 50-70 ngày).',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Line Chart
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 2.0,
                  maxY: 8.0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= widget.trendData.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              widget.trendData[index].month,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}x',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final point = widget.trendData[spot.spotIndex];
                          return LineTooltipItem(
                            'Tháng: ${point.month}\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            children: [
                              TextSpan(
                                text: 'Hệ số ITR: ${point.itr.toStringAsFixed(1)} vòng\n',
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              TextSpan(
                                text: 'COGS: ${CurrencyFormatter.formatCompactVND(point.cogs)}\n',
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                              TextSpan(
                                text: 'Tồn bình quân: ${CurrencyFormatter.formatCompactVND(point.avgStock)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(widget.trendData.length, (index) {
                        return FlSpot(index.toDouble(), widget.trendData[index].itr);
                      }),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.primaryLight,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryLight.withValues(alpha: 0.3),
                            AppColors.primaryLight.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
