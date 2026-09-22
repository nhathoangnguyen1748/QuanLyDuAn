/// Các thuật toán và công thức toán học tính toán quản trị kho hàng
class InventoryMath {
  /// 1. Tính giá vốn bình quân gia quyền (Moving Average Cost - MAC)
  /// Công thức: MAC_mới = [(Tồn_hiện_tại * Giá_vốn_cũ) + (SL_nhập_mới * Đơn_giá_nhập_mới)] / (Tồn_hiện_tại + SL_nhập_mới)
  static double calculateMAC({
    required int currentStock,
    required double currentCostPrice,
    required int newQuantity,
    required double newUnitPrice,
  }) {
    if (newQuantity <= 0) return currentCostPrice;
    if (currentStock <= 0) return newUnitPrice;

    final double totalCurrentValue = currentStock * currentCostPrice;
    final double totalNewValue = newQuantity * newUnitPrice;
    final int totalStock = currentStock + newQuantity;

    if (totalStock == 0) return newUnitPrice;
    return (totalCurrentValue + totalNewValue) / totalStock;
  }

  /// 2. Tính hệ số vòng quay hàng tồn kho (Inventory Turnover Ratio - ITR)
  /// ITR = Giá vốn hàng bán (COGS) / Giá trị tồn kho bình quân
  static double calculateITR({
    required double cogs,
    required double averageInventoryValue,
  }) {
    if (averageInventoryValue <= 0) return 0.0;
    return cogs / averageInventoryValue;
  }

  /// 3. Tính tỷ lệ lấp đầy kho (%)
  /// Utilization % = (Tổng lượng tồn hiện tại / Tổng sức chứa tối đa) * 100
  static double calculateUtilizationRate({
    required int totalCurrentUnits,
    required int totalCapacityUnits,
  }) {
    if (totalCapacityUnits <= 0) return 0.0;
    final double rate = (totalCurrentUnits / totalCapacityUnits) * 100;
    return rate > 100 ? 100.0 : rate;
  }

  /// 4. Phân loại ABC theo nguyên tắc Pareto (80 / 15 / 5)
  /// Trả về nhóm: 'A', 'B', hoặc 'C' dựa trên phần trăm tích lũy
  static String getABCClassification(double cumulativePercentage) {
    if (cumulativePercentage <= 80.0) {
      return 'A'; // Nhóm A: 80% giá trị
    } else if (cumulativePercentage <= 95.0) {
      return 'B'; // Nhóm B: 15% giá trị tiếp theo
    } else {
      return 'C'; // Nhóm C: 5% giá trị cuối
    }
  }

  /// 5. Tính chênh lệch kiểm kê (Variance)
  static int calculateVarianceQty({
    required int physicalCount,
    required int bookStock,
  }) {
    return physicalCount - bookStock;
  }

  /// Tính phần trăm sai lệch kiểm kê (%)
  static double calculateVariancePercent({
    required int physicalCount,
    required int bookStock,
  }) {
    if (bookStock == 0) {
      return physicalCount > 0 ? 100.0 : 0.0;
    }
    return ((physicalCount - bookStock) / bookStock) * 100.0;
  }
}
