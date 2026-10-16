import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';

/// Overlay de toasts style WhatsApp - bas de l'écran, fond solide, ombre marquée.
class ToastsOverlay extends StatelessWidget {
  const ToastsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (provider.toasts.isEmpty) return const SizedBox.shrink();
    final c = context.colors;

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in provider.toasts)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _ToastCarte(toast: t, couleurs: c),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToastCarte extends StatefulWidget {
  final ToastMessage toast;
  final AppColors couleurs;

  const _ToastCarte({required this.toast, required this.couleurs});

  @override
  State<_ToastCarte> createState() => _ToastCarteState();
}

class _ToastCarteState extends State<_ToastCarte> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    if (mounted) context.read<AppProvider>().fermerToast(widget.toast.id);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, bgColor, textColor) = switch (widget.toast.ton) {
      TonToast.succes => (
          Icons.check_circle_rounded,
          const Color(0xFF2E7D32), // Green 800
          Colors.white,
        ),
      TonToast.erreur => (
          Icons.error_rounded,
          const Color(0xFFC62828), // Red 800
          Colors.white,
        ),
      TonToast.info => (
          Icons.info_outline_rounded,
          const Color(0xFF1E88E5), // Blue 600
          Colors.white,
        ),
    };

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onTap: _dismiss,
          onHorizontalDragEnd: (_) => _dismiss(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: textColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.toast.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: textColor.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
