import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  final String tenantId;
  const AlertsScreen({super.key, required this.tenantId});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _api = ApiService();
  List<InventoryItem> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _api.fetchInventory(widget.tenantId);
      setState(() {
        _alerts = items.where((i) => i.isLowStock).toList();
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
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.violet.withOpacity(0.20), Colors.transparent]),
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
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => AppColors.duotoneGradient.createShader(b),
                            child: Text("Alerts",
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
                          ),
                          if (_alerts.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            _LivePulseDot(),
                          ],
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
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Triggered by EventBridge when stock drops below threshold",
                    style: Theme.of(context).textTheme.bodyMedium,
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
                      : _alerts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.emeraldGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(height: 16),
                                  Text("All stocked up", style: Theme.of(context).textTheme.headlineMedium),
                                  const SizedBox(height: 6),
                                  Text("No low-stock alerts right now",
                                      style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: AppColors.violet,
                              backgroundColor: AppColors.surface,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                itemCount: _alerts.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) => _AlertCard(
                                  item: _alerts[index],
                                  tenantId: widget.tenantId,
                                  onReturned: _load,
                                ),
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

class _LivePulseDot extends StatefulWidget {
  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final InventoryItem item;
  final String tenantId;
  final VoidCallback onReturned;

  const _AlertCard({required this.item, required this.tenantId, required this.onReturned});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item, tenantId: tenantId)),
        );
        if (changed == true) onReturned();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.violet.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(gradient: AppColors.violetGradient, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text("Only ${item.stockLevel} left · ${item.sku}",
                      style: const TextStyle(color: AppColors.violet, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}