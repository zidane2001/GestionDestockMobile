import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/logo_boutique.dart';
import 'connexion_screen.dart';
import 'home_screen.dart';

const _touches = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'bio', '0', 'suppr'];

class VerrouillageScreen extends StatefulWidget {
  const VerrouillageScreen({super.key});

  @override
  State<VerrouillageScreen> createState() => _VerrouillageScreenState();
}

class _VerrouillageScreenState extends State<VerrouillageScreen> {
  String _pin = '';
  String? _erreur;
  int _essais = 0;
  int _attente = 0;
  bool _afficherBiometrie = false;
  Timer? _minuteur;

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  void _verifier() {
    if (_pin.length != 4) return;
    final provider = context.read<AppProvider>();
    if (provider.deverrouiller(_pin)) {
      setState(() => _erreur = null);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }
    final n = _essais + 1;
    setState(() {
      _essais = n;
      _pin = '';
      if (n >= 5) {
        _attente = 30;
        _essais = 0;
        _erreur = '5 essais incorrects. Patientez 30 secondes.';
        _afficherBiometrie = true;
        _minuteur = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() {
            _attente -= 1;
            if (_attente <= 0) {
              _minuteur?.cancel();
              _erreur = null;
              _afficherBiometrie = false;
            }
          });
        });
        // Proposer biométrie si configurée
        final session = provider.session;
        if (session?.biometrie == true && (session?.pin ?? '').isNotEmpty) {
          _verifierBiometrie(provider);
        }
      } else {
        final restants = 5 - n;
        _erreur =
            'Code incorrect. $restants essai${restants > 1 ? 's' : ''} restant${restants > 1 ? 's' : ''}.';
      }
    });
  }

  Future<void> _verifierBiometrie(AppProvider provider) async {
    final success = await provider.verifierBiometrie();
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _appuyer(String touche) {
    if (_attente > 0) return;
    if (touche == 'suppr') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }
    if (touche == 'bio') {
      final provider = context.read<AppProvider>();
      final session = provider.session;
      if (session?.biometrie == true && (session?.pin ?? '').isNotEmpty) {
        _verifierBiometrie(provider);
      } else {
        provider.notifier('Biométrie non activée sur ce compte.', TonToast.info);
      }
      return;
    }
    if (_pin.length < 4) {
      setState(() {
        _pin = _pin + touche;
        _erreur = null;
      });
      if (_pin.length == 4) _verifier();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = context.watch<AppProvider>();
    final boutique = provider.boutique;
    final session = provider.session;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  LogoBoutique(logoUrl: boutique?.logoUrl, nom: boutique?.nom, taille: 56),
                  const SizedBox(height: 16),
                  Text(
                    boutique?.nom ?? '',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: c.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session != null ? '${roleLabel(session.role)} · ${session.nom}' : '',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 4; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _pin.length ? c.primary : Colors.transparent,
                            border: Border.all(
                              color: i < _pin.length ? c.primary : c.line,
                              width: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        _attente > 0 ? 'Nouvelle tentative dans $_attente s' : (_erreur ?? ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.danger),
                      ),
                    ),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        for (final t in _touches) _TouchePin(touche: t, surAppuyer: _appuyer, attente: _attente > 0),
                      ],
                    ),
                    if (_afficherBiometrie) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final provider = context.read<AppProvider>();
                            _verifierBiometrie(provider);
                          },
                          icon: const Icon(Icons.fingerprint_rounded, size: 20),
                          label: const Text('Utiliser la biométrie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => provider.notifier(
                            "Un code de vérification a été envoyé à l'email du patron.",
                            TonToast.info,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: c.primary,
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('PIN oublié ?'),
                        ),
                        const SizedBox(width: 24),
                        TextButton(
                          onPressed: () {
                            provider.deconnexion();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const ConnexionScreen()),
                              (route) => false,
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: c.muted,
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('Changer de compte'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TouchePin extends StatelessWidget {
  final String touche;
  final ValueChanged<String> surAppuyer;
  final bool attente;

  const _TouchePin({required this.touche, required this.surAppuyer, required this.attente});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (touche == 'bio') {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => surAppuyer(touche),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 64,
            child: Icon(Icons.fingerprint_rounded, size: 26, color: c.primary),
          ),
        ),
      );
    }
    if (touche == 'suppr') {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => surAppuyer(touche),
          borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 64,
              child: Icon(Icons.backspace_outlined, size: 22, color: c.muted),
            ),
        ),
      );
    }
    return Opacity(
      opacity: attente ? 0.4 : 1,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          onTap: attente ? null : () => surAppuyer(touche),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 64,
            child: Center(
              child: Text(
                touche,
                style: tnum(TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}