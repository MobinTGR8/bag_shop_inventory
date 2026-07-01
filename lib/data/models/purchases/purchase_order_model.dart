class PurchaseOrderModel {
  final String id;
  final String companyId;
  final String? supplierId;
  final String poNumber;
  final String status;
  final DateTime orderDate;
  final DateTime? expectedDelivery;
  final DateTime? actualDelivery;
  final double totalAmount;
  final String? notes;

  PurchaseOrderModel({
    required this.id,
    required this.companyId,
    required this.supplierId,
    required this.poNumber,
    required this.status,
    required this.orderDate,
    required this.expectedDelivery,
    required this.actualDelivery,
    required this.totalAmount,
    required this.notes,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      supplierId: json['supplier_id'] as String?,
      poNumber: (json['po_number'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'PENDING',
      orderDate: json['order_date'] == null
          ? DateTime.now()
          : DateTime.parse(json['order_date'] as String),
      expectedDelivery: json['expected_delivery'] == null
          ? null
          : DateTime.parse(json['expected_delivery'] as String),
      actualDelivery: json['actual_delivery'] == null
          ? null
          : DateTime.parse(json['actual_delivery'] as String),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'supplier_id': supplierId,
      'po_number': poNumber,
      'status': status,
      'order_date': orderDate.toIso8601String(),
      if (expectedDelivery != null)
        'expected_delivery': expectedDelivery!.toIso8601String(),
      if (actualDelivery != null)
        'actual_delivery': actualDelivery!.toIso8601String(),
      'total_amount': totalAmount,
      if (notes != null) 'notes': notes,
    };
  }
}
