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
                title: 'Tổng Giá Trị',
                value: CurrencyFormatter.formatCompactVND(kpi.totalInventoryValue),
                subtitle: '${kpi.totalUnits} đơn vị • ${kpi.totalSKUs} SKU',
                icon: Icons.account_balance_wallet,
                color: AppColors.primary,
                context: context,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                title: 'Tỷ Lệ Lấp Đầy',
                value: CurrencyFormatter.formatPercent(kpi.warehouseUtilizationRate),
                subtitle: '${kpi.totalUnits}/${kpi.totalCapacityUnits} vị trí',
                icon: Icons.warehouse,
                color: kpi.warehouseUtilizationRate > 85 ? AppColors.warning : AppColors.accent,
                progress: kpi.warehouseUtilizationRate / 100,
                context: context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Cần Nhập Hàng',
                value: '${kpi.lowStockCount} SKU',
                subtitle: kpi.lowStockCount > 0 ? 'Dưới mức an toàn' : 'Tồn kho ổn định',
                icon: Icons.warning_amber_rounded,
                color: kpi.lowStockCount > 0 ? AppColors.danger : AppColors.success,
                onTap: onLowStockTap,
                context: context,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                title: 'Hàng Chậm Bán',
                value: '${kpi.deadStockCount} SKU',
                subtitle: '>60 ngày chưa xuất',
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 11, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 9.5, color: AppColors.textMutedLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
