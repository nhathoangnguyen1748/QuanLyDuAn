import 'package:flutter_test/flutter_test.dart';
import 'package:smartstock_admin/core/utils/inventory_math.dart';

void main() {
  group('Kiểm thử Chỉ số Quản trị Kho Hàng (ITR, Pareto ABC, Chênh lệch Kiểm kê)', () {
    test('1. Tính Hệ số Vòng quay Hàng tồn kho (ITR)', () {
      // COGS = 600.000.000, Tồn kho bình quân = 120.000.000 => ITR = 5.0
      final itr = InventoryMath.calculateITR(
        cogs: 600000000,
        averageInventoryValue: 120000000,
      );

      expect(itr, equals(5.0));
    });

    test('Tính ITR khi tồn kho bình quân = 0 (tránh chia cho 0)', () {
      final itr = InventoryMath.calculateITR(
        cogs: 100000000,
        averageInventoryValue: 0,
      );

      expect(itr, equals(0.0));
    });

    test('2. Tính Tỷ lệ Lấp đầy Kho (Warehouse Capacity Utilization)', () {
      // 1500 đơn vị trên tổng sức chứa 2000 đơn vị => 75%
      final rate = InventoryMath.calculateUtilizationRate(
        totalCurrentUnits: 1500,
        totalCapacityUnits: 2000,
      );

      expect(rate, equals(75.0));
    });

    test('Tỷ lệ lấp đầy vượt ngưỡng thiết kế được giới hạn 100%', () {
      final rate = InventoryMath.calculateUtilizationRate(
        totalCurrentUnits: 2500,
        totalCapacityUnits: 2000,
      );

      expect(rate, equals(100.0));
    });

    test('3. Phân loại nhóm ABC theo Nguyên tắc Pareto (80/15/5)', () {
      expect(InventoryMath.getABCClassification(15.0), equals('A'));
      expect(InventoryMath.getABCClassification(79.9), equals('A'));
      expect(InventoryMath.getABCClassification(80.0), equals('A'));

      expect(InventoryMath.getABCClassification(80.1), equals('B'));
      expect(InventoryMath.getABCClassification(90.0), equals('B'));
      expect(InventoryMath.getABCClassification(95.0), equals('B'));

      expect(InventoryMath.getABCClassification(95.1), equals('C'));
      expect(InventoryMath.getABCClassification(100.0), equals('C'));
    });

    test('4. Tính Chênh lệch Đối soát Kiểm kê', () {
      // Sổ sách = 100, Thực tế = 95 => Lệch -5 (Thiếu)
      final varianceDeficit = InventoryMath.calculateVarianceQty(
        physicalCount: 95,
        bookStock: 100,
      );
      expect(varianceDeficit, equals(-5));

      final percentDeficit = InventoryMath.calculateVariancePercent(
        physicalCount: 95,
        bookStock: 100,
      );
      expect(percentDeficit, equals(-5.0));

      // Sổ sách = 80, Thực tế = 84 => Lệch +4 (Thừa)
      final varianceSurplus = InventoryMath.calculateVarianceQty(
        physicalCount: 84,
        bookStock: 80,
      );
      expect(varianceSurplus, equals(4));

      final percentSurplus = InventoryMath.calculateVariancePercent(
        physicalCount: 84,
        bookStock: 80,
      );
      expect(percentSurplus, equals(5.0));
    });
  });
}
