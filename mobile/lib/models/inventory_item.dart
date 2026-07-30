class HistoryEntry {
  final String status;
  final String timestamp;
  final String note;

  HistoryEntry({required this.status, required this.timestamp, required this.note});

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      status: json['status'] ?? '',
      timestamp: json['timestamp'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

class InventoryItem {
  final int id;
  final String tenantId;
  final String sku;
  final String name;
  final int stockLevel;
  final String createdAt;
  final String updatedAt;
  final List<HistoryEntry> history;

  InventoryItem({
    required this.id,
    required this.tenantId,
    required this.sku,
    required this.name,
    required this.stockLevel,
    required this.createdAt,
    required this.updatedAt,
    this.history = const [],
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
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => HistoryEntry.fromJson(e))
          .toList(),
    );
  }
}