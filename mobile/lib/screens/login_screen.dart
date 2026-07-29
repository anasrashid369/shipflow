import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController(text: "testuser@example.com");
  final _tenantController = TextEditingController(text: "tenant-a");
  bool _loading = false;
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _login() {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, anim, __) => FadeTransition(
            opacity: anim,
            child: DashboardScreen(tenantId: _tenantController.text.trim()),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -130,
            right: -90,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.emerald.withOpacity(0.28), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -110,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.violet.withOpacity(0.24), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppColors.duotoneGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emerald.withOpacity(0.35),
                                blurRadius: 30,
                                spreadRadius: -6,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: AppColors.violet.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: -6,
                                offset: const Offset(0, -6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 32),
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.duotoneGradient.createShader(bounds),
                          child: Text(
                            "ShipFlow",
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontSize: 38,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Sign in to manage inventory across\nyour workspace",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 40),
                        _GlassField(
                          label: "EMAIL",
                          controller: _emailController,
                          hint: "you@company.com",
                          icon: Icons.mail_outline_rounded,
                          accent: AppColors.emerald,
                        ),
                        const SizedBox(height: 16),
                        _GlassField(
                          label: "TENANT",
                          controller: _tenantController,
                          hint: "tenant-a",
                          icon: Icons.apartment_rounded,
                          accent: AppColors.violet,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.duotoneGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emerald.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _loading ? null : _login,
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Text("Sign in",
                                                style: TextStyle(
                                                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 6),
                            Text("Secured with AWS Cognito",
                                style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color accent;

  const _GlassField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon, size: 19, color: accent),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}