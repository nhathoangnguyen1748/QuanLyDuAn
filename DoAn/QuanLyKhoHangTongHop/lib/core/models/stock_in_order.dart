import 'dart:convert';

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
      skuId: (json['skuId'] ?? json['sku_id'] ?? '') as String,
      skuCode: (json['skuCode'] ?? json['sku_code'] ?? '') as String,
      skuName: (json['skuName'] ?? json['sku_name'] ?? '') as String,
      barcode: (json['barcode'] ?? '') as String,
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      unitPrice: ((json['unitPrice'] ?? json['unit_price'] ?? 0) as num).toDouble(),
      locationTag: (json['locationTag'] ?? json['location_tag'] ?? '') as String,
      currentCostBefore: ((json['currentCostBefore'] ?? json['current_cost_before'] ?? 0) as num).toDouble(),
      macAfter: ((json['macAfter'] ?? json['mac_after'] ?? 0) as num).toDouble(),
      expiryDate: (json['expiryDate'] ?? json['expiry_date']) != null
          ? DateTime.parse((json['expiryDate'] ?? json['expiry_date']) as String)
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
      'order_number': orderNumber,
      'supplier_name': supplierName,
      'supplier_phone': supplierPhone,
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'notes': notes,
      'status': status,
    };
  }

  factory StockInOrder.fromJson(Map<String, dynamic> json) {
    List<StockInItem> parsedItems = [];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          parsedItems.add(StockInItem.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          parsedItems.add(StockInItem.fromJson(jsonDecode(item) as Map<String, dynamic>));
        }
      }
    }

    return StockInOrder(
      id: (json['id'] ?? '') as String,
      orderNumber: (json['order_number'] ?? json['orderNumber'] ?? '') as String,
      supplierName: (json['supplier_name'] ?? json['supplierName'] ?? '') as String,
      supplierPhone: (json['supplier_phone'] ?? json['supplierPhone']) as String?,
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
