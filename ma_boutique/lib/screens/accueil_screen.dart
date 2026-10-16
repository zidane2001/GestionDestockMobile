import 'package:flutter/material.dart';

import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../widgets/ui/button.dart';
import 'admin_login_screen.dart';
import 'connexion_screen.dart';
import 'creer_boutique_screen.dart';

class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnim = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_boutique.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A2332),
                      Color(0xFF0E1621),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          // Content
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: child,
                ),
              );
            },
            child: SafeArea(
              child: Column(
                children: [
                  // Logo + app name centered in top area
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icon_smart_stock.png',
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.storefront_rounded,
                              size: 180,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Smart Stock',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 26,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Votre stock et votre caisse,\n',
                              ),
                              TextSpan(
                                text: "partagés avec l'équipe.",
                                style: TextStyle(
                                  color: c.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Bouton(
                          taille: TailleBouton.lg,
                          pleineLargeur: true,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreerBoutiqueScreen(),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Créer ma boutique'),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Bouton(
                          taille: TailleBouton.lg,
                          pleineLargeur: true,
                          variante: VarianteBouton.secondaire,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ConnexionScreen(),
                            ),
                          ),
                          child: const Text('Se connecter à ma boutique'),
                        ),
                        if (supabaseConfigure) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminLoginScreen(),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.transparent,
                              overlayColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                            ),
                            child: const Text(
                              'Espace administrateur →',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
