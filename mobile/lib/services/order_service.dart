import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class OrderService {
  static const String baseUrl = "http://localhost:3002";

  Future<List<Order>> fetchOrders(String tenantId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/orders"),
      headers: {"X-Tenant-Id": tenantId},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> orders = data['orders'] ?? [];
      return orders.map((e) => Order.fromJson(e)).toList();
    }
    throw Exception("Failed to load orders");
  }

  Future<Order> placeOrder(String tenantId, int itemId, String sku, int quantity) async {
    final response = await http.post(
      Uri.parse("$baseUrl/orders"),
      headers: {"Content-Type": "application/json", "X-Tenant-Id": tenantId},
      body: jsonEncode({"itemId": itemId, "sku": sku, "quantity": quantity}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data['order']);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['error'] ?? "Failed to place order");
  }
}