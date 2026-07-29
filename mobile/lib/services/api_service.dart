import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/inventory_item.dart';

class ApiService {
  static const String baseUrl = "http://localhost:3000";

  Future<List<InventoryItem>> fetchInventory(String tenantId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/inventory"),
      headers: {"X-Tenant-Id": tenantId},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => InventoryItem.fromJson(e)).toList();
    }
    throw Exception("Failed to load inventory");
  }

  Future<InventoryItem> createItem(String tenantId, String sku, String name, int stockLevel) async {
    final response = await http.post(
      Uri.parse("$baseUrl/inventory"),
      headers: {"Content-Type": "application/json", "X-Tenant-Id": tenantId},
      body: jsonEncode({"sku": sku, "name": name, "stock_level": stockLevel}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return InventoryItem.fromJson(data['item']);
    }
    throw Exception("Failed to create item");
  }

  Future<InventoryItem> updateStock(String tenantId, int id, int stockLevel) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/inventory/$id"),
      headers: {"Content-Type": "application/json", "X-Tenant-Id": tenantId},
      body: jsonEncode({"stock_level": stockLevel}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return InventoryItem.fromJson(data['item']);
    }
    throw Exception("Failed to update item");
  }
}