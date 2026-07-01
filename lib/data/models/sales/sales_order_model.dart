import 'package:equatable/equatable.dart';

class SalesOrderItem extends Equatable {
  final String? id;

  final String salesOrderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double discountPercent;
  final double? lineTotal;
  final String? warehouseId;
  final String? notes;

  const SalesOrderItem({
    this.id,
    required this.salesOrderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
    double? lineTotalParam,
    this.warehouseId,
    this.notes,
  }) : lineTotal = lineTotalParam ??
            (quantity * unitPrice * (1 - discountPercent / 100));

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    return SalesOrderItem(
      id: json['id'],
      salesOrderId: json['sales_order_id'],
      productId: json['product_id'],
      quantity: (json['quantity'] as int?) ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      lineTotalParam: (json['line_total'] as num?)?.toDouble(),
      warehouseId: json['warehouse_id'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sales_order_id': salesOrderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_percent': discountPercent,
      if (lineTotal != null) 'line_total': lineTotal,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        salesOrderId,
        productId,
        quantity,
        unitPrice,
        discountPercent,
        lineTotal,
        warehouseId,
        notes,
      ];
}

class SalesOrderModel extends Equatable {
  final String? id;
  final String? companyId;
  final String? customerId;
  final String? customerName;
  final String invoiceNumber;
  final String status;
  final DateTime saleDate;

  final DateTime? dueDate;

  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double shippingCharge;
  final double totalAmount;
  final double amountPaid;
  final double? balanceDue;

  final String? paymentMethod;
  final String paymentStatus;
  final Map<String, dynamic>? paymentSplit;

  final String? shippingAddress;
  final String? shippingMethod;
  final String? trackingNumber;

  final String? notes;

  final String? createdBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  final List<SalesOrderItem>? items;

  SalesOrderModel({
    this.id,
    this.companyId,
    this.customerId,
    this.customerName,
    required this.invoiceNumber,
    this.status = 'PENDING',
    DateTime? saleDate,
    this.dueDate,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.shippingCharge = 0,
    this.totalAmount = 0,
    this.amountPaid = 0,
    double? balanceDueParam,
    this.paymentMethod,
    this.paymentStatus = 'PENDING',
    this.paymentSplit,
    this.shippingAddress,
    this.shippingMethod,
    this.trackingNumber,
    this.notes,
    this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.items,
  })  : saleDate = saleDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        balanceDue = balanceDueParam ?? (totalAmount - amountPaid);

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderModel(
      id: json['id'],
      companyId: json['company_id'],
      customerId: json['customer_id'],
      customerName: json['customers'] is Map
          ? (json['customers'] as Map)['name'] as String?
          : json['customer_name'] as String?,
      invoiceNumber: (json['invoice_number'] as String?) ?? '',
      status: json['status'] ?? 'PENDING',
      saleDate: json['sale_date'] != null
          ? DateTime.parse(json['sale_date'])
          : DateTime.now(),
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      shippingCharge: (json['shipping_charge'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'PENDING',
      paymentSplit: json['payment_split'] is Map
          ? (json['payment_split'] as Map).cast<String, dynamic>()
          : null,
      shippingAddress: json['shipping_address'],
      shippingMethod: json['shipping_method'],
      trackingNumber: json['tracking_number'],
      notes: json['notes'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => SalesOrderItem.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      'invoice_number': invoiceNumber,
      'status': status,
      'sale_date': saleDate.toIso8601String(),
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'shipping_charge': shippingCharge,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      if (paymentSplit != null) 'payment_split': paymentSplit,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (shippingMethod != null) 'shipping_method': shippingMethod,
      if (trackingNumber != null) 'tracking_number': trackingNumber,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (items != null) 'items': items!.map((item) => item.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        customerId,
        customerName,
        invoiceNumber,
        status,
        saleDate,
        dueDate,
        subtotal,
        taxAmount,
        discountAmount,
        shippingCharge,
        totalAmount,
        amountPaid,
        balanceDue,
        paymentMethod,
        paymentStatus,
        paymentSplit,
        shippingAddress,
        shippingMethod,
        trackingNumber,
        notes,
        createdBy,
        createdAt,
        updatedAt,
        items,
      ];
}
