import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  final String tenantId;
  const OrdersScreen({super.key, required this.tenantId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _api = OrderService();
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _api.fetchOrders(widget.tenantId);
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.emerald.withOpacity(0.18), Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => AppColors.duotoneGradient.createShader(b),
                        child: Text("Orders",
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _load,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _loading
                      ? Center(
                          child: ShaderMask(
                            shaderCallback: (b) => AppColors.duotoneGradient.createShader(b),
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                        )
                      : _orders.isEmpty
                          ? Center(child: Text("No orders yet", style: Theme.of(context).textTheme.bodyMedium))
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppColors.emerald,
                              backgroundColor: AppColors.surface,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                itemCount: _orders.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) => _OrderCard(order: _orders[index]),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(gradient: AppColors.emeraldGradient, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${order.sku} × ${order.quantity}",
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(order.createdAt, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.emerald.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(order.status.toUpperCase(),
                style: const TextStyle(color: AppColors.emerald, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}