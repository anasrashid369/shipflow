class Order {
  final int id;
  final String tenantId;
  final String sku;
  final int quantity;
  final String status;
  final String createdAt;

  Order({
    required this.id,
    required this.tenantId,
    required this.sku,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      tenantId: json['tenant_id'] ?? '',
      sku: json['sku'] ?? '',
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? 'placed',
      createdAt: json['created_at'] ?? '',
    );
  }
}