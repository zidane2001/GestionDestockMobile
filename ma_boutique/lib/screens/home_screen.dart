import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_tabs.dart';
import '../widgets/sheets.dart';
import '../widgets/toasts_overlay.dart';
import 'actions_stock_view.dart';
import 'accueil_screen.dart';
import 'tableau_de_bord_view.dart';

enum TypeSheet { vente, defectueux, retour, depense, sortie, produit }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Onglet _onglet = Onglet.tableau;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changerOnglet(Onglet o) {
    setState(() => _onglet = o);
    _pageController.animateToPage(
      o == Onglet.tableau ? 0 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _ouvrirSheet(TypeSheet? type, {Produit? produit}) async {
    if (type == null) return;
    switch (type) {
      case TypeSheet.vente:
        await ouvrirVenteSheet(context, produit);
        break;
      case TypeSheet.defectueux:
        await ouvrirDefectueuxSheet(context, produit);
        break;
      case TypeSheet.retour:
        await ouvrirRetourSheet(context, produit);
        break;
      case TypeSheet.depense:
        await ouvrirDepenseSheet(context, TypeDepense.depense);
        break;
      case TypeSheet.sortie:
        await ouvrirDepenseSheet(context, TypeDepense.sortieJustifiee);
        break;
      case TypeSheet.produit:
        await ouvrirProduitSheet(context, produit);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final boutique = context.watch<AppProvider>().boutique;
    if (boutique?.estDesactivee ?? false) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_rounded, size: 64, color: c.danger),
                  const SizedBox(height: 16),
                  Text(
                    'Boutique désactivée',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Votre boutique a été désactivée par l\'administrateur.\n'
                    'Contactez-le pour régulariser votre abonnement et la réactiver.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5, color: c.muted),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<AppProvider>().deconnexion();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AccueilScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const AppHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) =>
                        setState(() => _onglet = i == 0 ? Onglet.tableau : Onglet.actions),
                    children: [
                      TableauDeBordView(onOuvrirActions: () => _changerOnglet(Onglet.actions)),
                      ActionsStockView(onOuvrirSheet: _ouvrirSheet),
                    ],
                  ),
                ),
                BottomTabs(
                  actif: _onglet,
                  onChange: _changerOnglet,
                ),
              ],
            ),
            const ToastsOverlay(),
          ],
        ),
      ),
    );
  }
}