class ExecutiveKPI {
  final double totalInventoryValue;
  final double warehouseUtilizationRate; // 0 - 100 %
  final int lowStockCount;
  final int deadStockCount;
  final int totalSKUs;
  final int totalUnits;
  final int totalCapacityUnits;
  final int expiringSoonCount;
  final int expiredCount;

  const ExecutiveKPI({
    required this.totalInventoryValue,
    required this.warehouseUtilizationRate,
    required this.lowStockCount,
    required this.deadStockCount,
    required this.totalSKUs,
    required this.totalUnits,
    required this.totalCapacityUnits,
    required this.expiringSoonCount,
    required this.expiredCount,
  });
}

class ParetoABCItem {
  final String skuId;
  final String skuCode;
  final String name;
  final double revenueValue;
  final double valueSharePercent; // % đóng góp
  final double cumulativePercent; // % tích lũy
  final String group; // 'A', 'B', 'C'

  const ParetoABCItem({
    required this.skuId,
    required this.skuCode,
    required this.name,
    required this.revenueValue,
    required this.valueSharePercent,
    required this.cumulativePercent,
    required this.group,
  });
}

class ParetoAnalysisResult {
  final List<ParetoABCItem> items;
  final double groupAValueShare;
  final double groupBValueShare;
  final double groupCValueShare;
  final int groupACount;
  final int groupBCount;
  final int groupCCount;

  const ParetoAnalysisResult({
    required this.items,
    required this.groupAValueShare,
    required this.groupBValueShare,
    required this.groupCValueShare,
    required this.groupACount,
    required this.groupBCount,
    required this.groupCCount,
  });
}

class ITRDataPoint {
  final String month;
  final double itr; // Inventory Turnover Ratio
  final double cogs; // Cost of Goods Sold
  final double avgStock; // Tồn kho bình quân

  const ITRDataPoint({
    required this.month,
    required this.itr,
    required this.cogs,
    required this.avgStock,
  });
}

class HoldingCostDataPoint {
  final String period;
  final double storageCost; // Chi phí thuê kho & vận hành
  final double shrinkageCost; // Hao hụt, hư hỏng
  final double revenue; // Doanh thu

  const HoldingCostDataPoint({
    required this.period,
    required this.storageCost,
    required this.shrinkageCost,
    required this.revenue,
  });
}

class CategoryDistributionItem {
  final String categoryId;
  final String categoryName;
  final int colorHex;
  final int skuCount;
  final int totalStockUnits;
  final double totalValue;
  final double percentage; // 0 - 100%

  const CategoryDistributionItem({
    required this.categoryId,
    required this.categoryName,
    required this.colorHex,
    required this.skuCount,
    required this.totalStockUnits,
    required this.totalValue,
    required this.percentage,
  });
}
