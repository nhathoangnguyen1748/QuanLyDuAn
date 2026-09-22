import 'package:flutter_test/flutter_test.dart';
import 'package:smartstock_admin/core/utils/currency_formatter.dart';
import 'package:smartstock_admin/core/utils/date_formatter.dart';
import 'package:smartstock_admin/core/utils/inventory_math.dart';

void main() {
  test('Kiểm tra formatters và logic quản trị kho', () {
    // 1. Kiểm tra format tiền VND
    expect(CurrencyFormatter.formatVND(1500000), contains('1.500.000'));
    expect(CurrencyFormatter.formatCompactVND(1500000000), contains('1.5 Tỷ'));
    expect(CurrencyFormatter.formatCompactVND(350000000), contains('350.0 Tr'));

    // 2. Kiểm tra format ngày
    final testDate = DateTime(2026, 9, 22);
    expect(DateFormatter.formatDate(testDate), equals('22/09/2026'));

    // 3. Kiểm tra MAC logic
    final mac = InventoryMath.calculateMAC(
      currentStock: 20,
      currentCostPrice: 50000,
      newQuantity: 10,
      newUnitPrice: 80000,
    );
    // (20*50000 + 10*80000) / 30 = (1000000 + 800000) / 30 = 60000
    expect(mac, equals(60000.0));
  });
}
