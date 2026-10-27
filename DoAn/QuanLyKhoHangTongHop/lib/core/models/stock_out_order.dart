import 'dart:convert';

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
      skuId: (json['skuId'] ?? json['sku_id'] ?? '') as String,
      skuCode: (json['skuCode'] ?? json['sku_code'] ?? '') as String,
      skuName: (json['skuName'] ?? json['sku_name'] ?? '') as String,
      barcode: (json['barcode'] ?? '') as String,
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      unitPrice: ((json['unitPrice'] ?? json['unit_price'] ?? 0) as num).toDouble(),
      costPrice: ((json['costPrice'] ?? json['cost_price'] ?? 0) as num).toDouble(),
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
      'order_number': orderNumber,
      'type': type.name,
      'receiver_name': receiverName,
      'destination_branch': destinationBranch,
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'notes': notes,
      'status': status,
    };
  }

  factory StockOutOrder.fromJson(Map<String, dynamic> json) {
    List<StockOutItem> parsedItems = [];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          parsedItems.add(StockOutItem.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          parsedItems.add(StockOutItem.fromJson(jsonDecode(item) as Map<String, dynamic>));
        }
      }
    }

    final rawType = (json['type'] ?? 'retail') as String;
    return StockOutOrder(
      id: (json['id'] ?? '') as String,
      orderNumber: (json['order_number'] ?? json['orderNumber'] ?? '') as String,
      type: StockOutType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => StockOutType.retail,
      ),
      receiverName: (json['receiver_name'] ?? json['receiverName'] ?? '') as String,
      destinationBranch: (json['destination_branch'] ?? json['destinationBranch']) as String?,
      items: parsedItems,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.parse((json['created_at'] ?? json['createdAt']) as String)
          : DateTime.now(),
      createdBy: (json['created_by'] ?? json['createdBy'] ?? 'Admin Kho') as String,
      notes: json['notes'] as String?,
      status: (json['status'] ?? 'COMPLETED') as String,
    );
  }
}
