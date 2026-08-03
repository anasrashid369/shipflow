import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  final String tenantId;
  const SettingsScreen({super.key, required this.tenantId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  int _threshold = 10;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await _api.fetchThreshold(widget.tenantId);
      setState(() {
        _threshold = t;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateThreshold(widget.tenantId, _threshold);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Threshold updated")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save")),
        );
      }
    } finally {
      setState(() => _saving = false);
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
                gradient: RadialGradient(colors: [AppColors.violet.withOpacity(0.18), Colors.transparent]),
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
                      Text("Settings", style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          children: [
                            Text("TENANT", style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.apartment_rounded, size: 18, color: AppColors.textTertiary),
                                  const SizedBox(width: 10),
                                  Text(widget.tenantId,
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text("LOW STOCK THRESHOLD", style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 6),
                            Text(
                              "Items below this quantity will trigger an alert",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (b) => AppColors.duotoneGradient.createShader(b),
                                    child: Text(
                                      "$_threshold",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text("units", style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                                  const SizedBox(height: 20),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppColors.violet,
                                      inactiveTrackColor: AppColors.border,
                                      thumbColor: AppColors.emerald,
                                      overlayColor: AppColors.emerald.withOpacity(0.2),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _threshold.toDouble(),
                                      min: 0,
                                      max: 50,
                                      divisions: 50,
                                      onChanged: (v) => setState(() => _threshold = v.round()),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text("0", style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                      Text("50", style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(gradient: AppColors.duotoneGradient, borderRadius: BorderRadius.circular(14)),
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
                                          : const Text("Save",
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
}