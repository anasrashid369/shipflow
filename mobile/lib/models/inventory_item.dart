class InventoryItem {
  final int id;
  final String tenantId;
  final String sku;
  final String name;
  final int stockLevel;
  final String createdAt;
  final String updatedAt;

  InventoryItem({
    required this.id,
    required this.tenantId,
    required this.sku,
    required this.name,
    required this.stockLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stockLevel < 10;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      tenantId: json['tenant_id'] ?? '',
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      stockLevel: json['stock_level'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}