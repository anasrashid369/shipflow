import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final InventoryItem item;
  final String tenantId;
  const ItemDetailScreen({super.key, required this.item, required this.tenantId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ApiService _api = ApiService();
  late int _stock;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stock = widget.item.stockLevel;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateStock(widget.tenantId, widget.item.id, _stock);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = _stock < 10;
    final accent = lowStock ? AppColors.violet : AppColors.emerald;
    final gradient = lowStock ? AppColors.violetGradient : AppColors.emeraldGradient;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [accent.withOpacity(0.18), Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                      ),
                      Text("Item details", style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
                            child: Icon(
                              lowStock ? Icons.warning_rounded : Icons.inventory_2_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.item.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(widget.item.sku,
                                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Text("STOCK LEVEL", style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _stepperButton(Icons.remove_rounded, () {
                                  if (_stock > 0) setState(() => _stock--);
                                }),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    "$_stock",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: accent, fontSize: 44, fontWeight: FontWeight.w800, height: 1),
                                  ),
                                ),
                                _stepperButton(Icons.add_rounded, () => setState(() => _stock++)),
                              ],
                            ),
                            if (lowStock) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.violet.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text("Below threshold — will trigger an alert",
                                    style: TextStyle(color: AppColors.violet, fontSize: 11.5, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _saving ? null : _save,
                              child: Center(
                                child: _saving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text("Save changes",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text("TIMELINE", style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 14),
                      if (widget.item.history.isEmpty)
                        Text("No history yet", style: Theme.of(context).textTheme.bodyMedium)
                      else
                        ...widget.item.history.reversed.map((h) => _TimelineTile(entry: h)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final HistoryEntry entry;
  const _TimelineTile({required this.entry});

  Color get _color {
    switch (entry.status) {
      case 'escalated':
        return AppColors.violet;
      case 'acknowledged':
        return AppColors.emerald;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.note,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(entry.timestamp, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}