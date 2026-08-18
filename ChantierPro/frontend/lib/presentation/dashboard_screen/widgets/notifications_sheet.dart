import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/app_strings.dart';
import '../../../core/models/alerte.dart';
import '../../../core/models/chantier.dart';
import '../../../core/models/tache.dart';
import '../../../core/utils/chantier_mapper.dart';
import '../../../theme/app_theme.dart';

/// Élément de notification affiché dans le panneau.
class AppNotification {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Chantier? chantier;

  const AppNotification({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.chantier,
  });
}

/// Construit la liste des notifications à partir des données réelles :
/// chantiers en retard, tâches en retard, alertes du backend.
List<AppNotification> buildNotifications({
  required List<Chantier> chantiers,
  required List<Tache> taches,
  required List<Alerte> alertes,
  required String lang,
}) {
  String s(String k) => AppStrings.get(k, lang);
  Chantier? findChantier(int? id) {
    if (id == null) return null;
    for (final c in chantiers) {
      if (c.id == id) return c;
    }
    return null;
  }

  final notifications = <AppNotification>[];

  for (final c in chantiers.where((c) => c.statut == 'retard')) {
    notifications.add(
      AppNotification(
        icon: Icons.construction_rounded,
        color: AppTheme.statusRetard,
        title: '${s('late_chantier')} : ${c.nom}',
        subtitle: c.localisation,
        chantier: c,
      ),
    );
  }

  for (final t in taches.where((t) => t.isEnRetard)) {
    final chantier = findChantier(t.chantierId);
    notifications.add(
      AppNotification(
        icon: Icons.warning_amber_rounded,
        color: AppTheme.statusEnAttente,
        title: '${s('late_task')} : ${t.titre}',
        subtitle:
            chantier?.nom ?? (t.dateFin != null ? formatDate(t.dateFin!) : ''),
        chantier: chantier,
      ),
    );
  }

  for (final a in alertes) {
    final chantier = findChantier(a.chantierId);
    notifications.add(
      AppNotification(
        icon: Icons.notification_important_rounded,
        color: AppTheme.primary,
        title: a.message,
        subtitle:
            '${chantier?.nom ?? '—'}${a.dateCreation != null ? ' · ${formatDate(a.dateCreation!)}' : ''}',
        chantier: chantier,
      ),
    );
  }

  return notifications;
}

/// Affiche le panneau de notifications. [onOpenChantier] est appelé
/// avec le chantier concerné quand l'utilisateur touche une notification.
void showNotificationsSheet(
  BuildContext context, {
  required List<AppNotification> notifications,
  required void Function(Chantier chantier) onOpenChantier,
}) {
  final lang = AppState().locale.languageCode;
  String s(String k) => AppStrings.get(k, lang);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  s('notifications'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                if (notifications.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.statusRetard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${notifications.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 56,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s('no_notifications'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha(120),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        onTap: n.chantier != null
                            ? () {
                                Navigator.pop(ctx);
                                onOpenChantier(n.chantier!);
                              }
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: n.color.withAlpha(31),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(n.icon, color: n.color, size: 20),
                        ),
                        title: Text(
                          n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          n.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: n.chantier != null
                            ? Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}
