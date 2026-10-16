import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/sub_screen.dart';
import '../widgets/ui/empty_state.dart';

IconData _iconeNotif(NotifType type) {
  switch (type) {
    case NotifType.vente:
      return Icons.shopping_cart_outlined;
    case NotifType.depense:
      return Icons.receipt_long_outlined;
    case NotifType.stock:
      return Icons.warning_amber_rounded;
    case NotifType.produit:
      return Icons.add_box_outlined;
    case NotifType.retour:
      return Icons.swap_horiz_rounded;
    case NotifType.compte:
      return Icons.admin_panel_settings_outlined;
    case NotifType.pointage:
      return Icons.schedule_rounded;
    case NotifType.connexion:
      return Icons.login_rounded;
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    _minuteur = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) context.read<AppProvider>().marquerNotificationsLues();
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final liste = provider.notificationsRole;
    final nonLues = liste.where((n) => !n.estLu).length;

    return SubScreen(
      titre: 'Notifications',
      sousTitre: nonLues > 0 ? '$nonLues non lue${nonLues > 1 ? 's' : ''}' : 'Tout est à jour',
      action: nonLues > 0
          ? TextButton(
              onPressed: provider.marquerNotificationsLues,
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('Tout marquer lu'),
            )
          : null,
      enfant: liste.isEmpty
          ? const EtatVide(
              icone: Icons.notifications_none_rounded,
              titre: 'Aucune notification',
              texte: "Les ventes, dépenses et alertes de stock de l'équipe s'afficheront ici.",
            )
          : Column(
              children: [
                for (final n in liste)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: n.estLu ? c.canvas : c.surface,
                      border: Border(top: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: n.estLu ? c.surface2 : c.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _iconeNotif(n.type),
                            size: 17,
                            color: n.estLu ? c.muted : c.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.titre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(ilYA(n.date), style: TextStyle(fontSize: 12, color: c.muted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.message,
                                style: TextStyle(fontSize: 13, height: 1.3, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                        if (!n.estLu)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: c.primary,
                              shape: BoxShape.circle,
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