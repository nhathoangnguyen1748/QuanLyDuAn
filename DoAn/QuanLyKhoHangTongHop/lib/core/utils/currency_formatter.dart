import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Format số tiền chuẩn VND: 1.250.000 ₫
  static String formatVND(num amount) {
    return _vndFormat.format(amount).trim();
  }

  /// Format số tiền rút gọn cho biểu đồ & KPI: 1.2 Tỷ, 350 Tr, 50 K
  static String formatCompactVND(num amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} Tỷ ₫';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} Tr ₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} K ₫';
    }
    return '${amount.toStringAsFixed(0)} ₫';
  }

  /// Format số lượng có dấu phân cách nghìn: 1,500
  static String formatNumber(num value) {
    return _numberFormat.format(value);
  }

  /// Format phần trăm: 85.5%
  static String formatPercent(double percent, {int decimals = 1}) {
    return '${percent.toStringAsFixed(decimals)}%';
  }
}
