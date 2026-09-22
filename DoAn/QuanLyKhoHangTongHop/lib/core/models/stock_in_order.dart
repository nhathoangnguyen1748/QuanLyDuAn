class StockInItem {
  final String skuId;
  final String skuCode;
  final String skuName;
  final String barcode;
  final int quantity;
  final double unitPrice;
  final String locationTag; // Kệ phân bổ: KHO-A-KAY-03
  final double currentCostBefore; // Giá vốn cũ
  final double macAfter; // Giá vốn bình quân sau khi nhập
  final DateTime? expiryDate;

  const StockInItem({
    required this.skuId,
    required this.skuCode,
    required this.skuName,
    required this.barcode,
    required this.quantity,
    required this.unitPrice,
    required this.locationTag,
    required this.currentCostBefore,
    required this.macAfter,
    this.expiryDate,
  });

  double get totalAmount => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'skuId': skuId,
      'skuCode': skuCode,
      'skuName': skuName,
      'barcode': barcode,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'locationTag': locationTag,
      'currentCostBefore': currentCostBefore,
      'macAfter': macAfter,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory StockInItem.fromJson(Map<String, dynamic> json) {
    return StockInItem(
      skuId: json['skuId'] as String,
      skuCode: json['skuCode'] as String,
      skuName: json['skuName'] as String,
      barcode: json['barcode'] as String? ?? '',
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      locationTag: json['locationTag'] as String,
      currentCostBefore: (json['currentCostBefore'] as num).toDouble(),
      macAfter: (json['macAfter'] as num).toDouble(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
    );
  }
}

class StockInOrder {
  final String id;
  final String orderNumber; // Mã phiếu: PNK-2026-001
  final String supplierName;
  final String? supplierPhone;
  final List<StockInItem> items;
  final DateTime createdAt;
  final String createdBy;
  final String? notes;
  final String status; // 'COMPLETED', 'PENDING'

  const StockInOrder({
    required this.id,
    required this.orderNumber,
    required this.supplierName,
    this.supplierPhone,
    required this.items,
    required this.createdAt,
    this.createdBy = 'Admin Kho',
    this.notes,
    this.status = 'COMPLETED',
  });

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalValue => items.fold(0.0, (sum, item) => sum + item.totalAmount);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'supplierName': supplierName,
      'supplierPhone': supplierPhone,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'notes': notes,
      'status': status,
    };
  }

  factory StockInOrder.fromJson(Map<String, dynamic> json) {
    return StockInOrder(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      supplierName: json['supplierName'] as String,
      supplierPhone: json['supplierPhone'] as String?,
      items: (json['items'] as List)
          .map((i) => StockInItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String? ?? 'Admin Kho',
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'COMPLETED',
    );
  }
}
