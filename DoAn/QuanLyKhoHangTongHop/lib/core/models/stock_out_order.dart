enum StockOutType {
  retail('Bán lẻ', 'Xuất bán khách lẻ tại quầy'),
  wholesale('Bán sỉ', 'Xuất bán buôn số lượng lớn'),
  transfer('Điều chuyển nội bộ', 'Chuyển hàng sang chi nhánh kho khác');

  final String label;
  final String description;
  const StockOutType(this.label, this.description);
}

class StockOutItem {
  final String skuId;
  final String skuCode;
  final String skuName;
  final String barcode;
  final int quantity;
  final double unitPrice; // Giá bán
  final double costPrice; // Giá vốn tại thời điểm xuất (phục vụ tính COGS)

  const StockOutItem({
    required this.skuId,
    required this.skuCode,
    required this.skuName,
    required this.barcode,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
  });

  double get totalRevenue => quantity * unitPrice;
  double get totalCogs => quantity * costPrice;
  double get profit => totalRevenue - totalCogs;

  Map<String, dynamic> toJson() {
    return {
      'skuId': skuId,
      'skuCode': skuCode,
      'skuName': skuName,
      'barcode': barcode,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'costPrice': costPrice,
    };
  }

  factory StockOutItem.fromJson(Map<String, dynamic> json) {
    return StockOutItem(
      skuId: json['skuId'] as String,
      skuCode: json['skuCode'] as String,
      skuName: json['skuName'] as String,
      barcode: json['barcode'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      costPrice: (json['costPrice'] as num).toDouble(),
    );
  }
}

class StockOutOrder {
  final String id;
  final String orderNumber; // PXK-2026-001
  final StockOutType type;
  final String receiverName; // Tên khách hàng / Chi nhánh nhận
  final String? destinationBranch; // Áp dụng khi điều chuyển
  final List<StockOutItem> items;
  final DateTime createdAt;
  final String createdBy;
  final String? notes;
  final String status;

  const StockOutOrder({
    required this.id,
    required this.orderNumber,
    required this.type,
    required this.receiverName,
    this.destinationBranch,
    required this.items,
    required this.createdAt,
    this.createdBy = 'Admin Kho',
    this.notes,
    this.status = 'COMPLETED',
  });

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalRevenue => items.fold(0.0, (sum, item) => sum + item.totalRevenue);
  double get totalCogs => items.fold(0.0, (sum, item) => sum + item.totalCogs);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'type': type.name,
      'receiverName': receiverName,
      'destinationBranch': destinationBranch,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'notes': notes,
      'status': status,
    };
  }

  factory StockOutOrder.fromJson(Map<String, dynamic> json) {
    return StockOutOrder(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      type: StockOutType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StockOutType.retail,
      ),
      receiverName: json['receiverName'] as String,
      destinationBranch: json['destinationBranch'] as String?,
      items: (json['items'] as List)
          .map((i) => StockOutItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String? ?? 'Admin Kho',
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'COMPLETED',
    );
  }
}
