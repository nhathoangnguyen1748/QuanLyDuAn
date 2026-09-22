import 'package:flutter/material.dart';
import 'package:smartstock_admin/core/constants/app_colors.dart';
import 'package:smartstock_admin/core/models/analytics_models.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';

class KPISummaryGrid extends StatelessWidget {
  final ExecutiveKPI kpi;
  final VoidCallback? onLowStockTap;
  final VoidCallback? onDeadStockTap;

  const KPISummaryGrid({
    super.key,
    required this.kpi,
    this.onLowStockTap,
    this.onDeadStockTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Tổng Giá Trị Tồn Kho',
                value: CurrencyFormatter.formatCompactVND(kpi.totalInventoryValue),
                subtitle: '${CurrencyFormatter.formatNumber(kpi.totalUnits)} đơn vị (${kpi.totalSKUs} SKU)',
                icon: Icons.account_balance_wallet,
                color: AppColors.primary,
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Tỷ Lệ Lấp Đầy Kho',
                value: CurrencyFormatter.formatPercent(kpi.warehouseUtilizationRate),
                subtitle: '${kpi.totalUnits}/${kpi.totalCapacityUnits} vị trí lưu trữ',
                icon: Icons.warehouse,
                color: kpi.warehouseUtilizationRate > 85 ? AppColors.warning : AppColors.accent,
                progress: kpi.warehouseUtilizationRate / 100,
                context: context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Dưới Mức An Toàn',
                value: '${kpi.lowStockCount} SKU',
                subtitle: kpi.lowStockCount > 0 ? 'Cần bổ sung nhập hàng gấp' : 'Tồn kho ổn định',
                icon: Icons.warning_amber_rounded,
                color: kpi.lowStockCount > 0 ? AppColors.danger : AppColors.success,
                onTap: onLowStockTap,
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Tồn Kho Chậm Luân Chuyển',
                value: '${kpi.deadStockCount} SKU',
                subtitle: 'Không xuất trong >60 ngày',
                icon: Icons.hourglass_bottom_rounded,
                color: kpi.deadStockCount > 0 ? AppColors.accentAmber : AppColors.textSecondaryLight,
                onTap: onDeadStockTap,
                context: context,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
    VoidCallback? onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: onTap != null ? color.withValues(alpha: 0.3) : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 12, color: color),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (progress != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
