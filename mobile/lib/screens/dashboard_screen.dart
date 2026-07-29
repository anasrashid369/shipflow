import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String tenantId;
  const DashboardScreen({super.key, required this.tenantId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();
  List<InventoryItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.fetchInventory(widget.tenantId);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Couldn't load inventory";
      });
    }
  }

  int get _lowStockCount => _items.where((i) => i.isLowStock).length;
  int get _totalUnits => _items.fold(0, (sum, i) => sum + i.stockLevel);

  void _showAddItemSheet() {
    final skuController = TextEditingController();
    final nameController = TextEditingController();
    final stockController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 28,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.92),
                border: Border(top: BorderSide(color: AppColors.violet.withOpacity(0.3))),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (b) => AppColors.duotoneGradient.createShader(b),
                    child: Text("Add item",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  _sheetField(skuController, "SKU", Icons.qr_code_rounded),
                  const SizedBox(height: 12),
                  _sheetField(nameController, "Item name", Icons.label_outline_rounded),
                  const SizedBox(height: 12),
                  _sheetField(stockController, "Stock level", Icons.numbers_rounded, isNumber: true),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.duotoneGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final stock = int.tryParse(stockController.text) ?? 0;
                            if (skuController.text.isEmpty || nameController.text.isEmpty) return;
                            Navigator.pop(ctx);
                            try {
                              await _api.createItem(
                                  widget.tenantId, skuController.text, nameController.text, stock);
                              _load();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text("Failed to add item")));
                              }
                            }
                          },
                          child: const Center(
                            child: Text("Add item",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetField(TextEditingController c, String hint, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.violet.withOpacity(0.16), Colors.transparent]),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => AppColors.duotoneGradient.createShader(b),
                            child: Text("Inventory",
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.apartment_rounded, size: 13, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(widget.tenantId, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ],
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: "Total units",
                          value: "$_totalUnits",
                          icon: Icons.inventory_2_rounded,
                          gradient: AppColors.emeraldGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: "Low stock",
                          value: "$_lowStockCount",
                          icon: Icons.warning_rounded,
                          gradient: AppColors.violetGradient,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text("ITEMS", style: Theme.of(context).textTheme.labelSmall),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? Center(
                          child: ShaderMask(
                            shaderCallback: (b) => AppColors.duotoneGradient.createShader(b),
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                        )
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
                          : _items.isEmpty
                              ? Center(
                                  child: Text("No items yet", style: Theme.of(context).textTheme.bodyMedium))
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  color: AppColors.violet,
                                  backgroundColor: AppColors.surface,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                    itemCount: _items.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) =>
                                        _ItemCard(item: _items[index], delay: index * 60),
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.duotoneGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.emerald.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddItemSheet,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({required this.label, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ItemCard extends StatefulWidget {
  final InventoryItem item;
  final int delay;
  const _ItemCard({required this.item, required this.delay});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final lowStock = item.isLowStock;
    final accentGradient = lowStock ? AppColors.violetGradient : AppColors.emeraldGradient;
    final accentColor = lowStock ? AppColors.violet : AppColors.emerald;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: lowStock ? AppColors.violet.withOpacity(0.35) : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(gradient: accentGradient, borderRadius: BorderRadius.circular(12)),
              child: Icon(
                lowStock ? Icons.warning_rounded : Icons.inventory_2_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(item.sku, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${item.stockLevel}",
                    style: TextStyle(color: accentColor, fontSize: 17, fontWeight: FontWeight.w800)),
                const Text("in stock", style: TextStyle(color: AppColors.textTertiary, fontSize: 10.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}