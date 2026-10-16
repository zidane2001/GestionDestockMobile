import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../screens/notifications_screen.dart';
import '../screens/parametres_screen.dart';
import 'logo_boutique.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final c = context.colors;
    final boutique = provider.boutique;
    final session = provider.session;
    final nonLues = provider.notificationsRole.where((n) => !n.estLu).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          LogoBoutique(logoUrl: boutique?.logoUrl, nom: boutique?.nom, taille: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boutique?.nom ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.ink),
                ),
                const SizedBox(height: 1),
                Text(
                  session != null
                      ? '${session.role.label} · ${session.nom}'
                      : '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
                if (!provider.enLigne)
                  Text(
                    'Hors ligne · ${provider.enAttenteSync} en attente',
                    style: TextStyle(fontSize: 12, color: c.accent),
                  )
                else if (provider.enAttenteSync > 0)
                  Text(
                    '${provider.enAttenteSync} en attente de synchro',
                    style: TextStyle(fontSize: 12, color: c.accent),
                  )
                else if (provider.tempsReel)
                  Text(
                    'Synchronisation en direct',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
              ],
            ),
          ),
          _BoutonRond(
            icone: Icons.cloud_sync_outlined,
            surTap: () {
              provider.synchroniserMaintenant();
            },
          ),
          const SizedBox(width: 8),
          _BoutonRond(
            badge: nonLues,
            icone: Icons.notifications_none_rounded,
            surTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _BoutonRond(
            icone: Icons.settings_outlined,
            surTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ParametresScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  final IconData icone;
  final int badge;
  final VoidCallback surTap;

  const _BoutonRond({required this.icone, this.badge = 0, required this.surTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: c.surface2,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: surTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icone, size: 18, color: c.ink),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: c.danger,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '$badge',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: c.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}