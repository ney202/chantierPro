import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class ChantierListItemWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const ChantierListItemWidget({
    required this.data,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ChantierStatusExt.fromString(data['status'] as String);
    final progress = data['progress'] as double;
    final budget = data['budget'] as double;
    final budgetConsomme = data['budgetConsomme'] as double;
    final budgetPct = budget > 0 ? (budgetConsomme / budget) : 0.0;
    final isRetard = status == ChantierStatus.retard;
    final nbTaches = data['nbTaches'] as int;
    final tachesTerminees = data['tachesTerminees'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isRetard ? AppTheme.statusRetard : AppTheme.primary,
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primary.withAlpha(20),
          highlightColor: AppTheme.primary.withAlpha(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color:
                            (isRetard
                                    ? AppTheme.statusRetard
                                    : AppTheme.primary)
                                .withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        size: 22,
                        color: isRetard
                            ? AppTheme.statusRetard
                            : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['name'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadgeWidget(status: status, compact: true),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  data['address'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MetricChip(
                      icon: Icons.payments_rounded,
                      value: _formatBudget(budget),
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 8),
                    _MetricChip(
                      icon: Icons.task_alt_rounded,
                      value: '$tachesTerminees/$nbTaches tâches',
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _MetricChip(
                      icon: Icons.person_outline_rounded,
                      value: _shortName(data['chefChantier'] as String),
                      color: AppTheme.statusPlanifie,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Avancement: ${(progress * 100).toInt()}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Budget: ${(budgetPct * 100).toInt()}% consommé',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: budgetPct > 0.9
                            ? AppTheme.statusRetard
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isRetard ? AppTheme.statusRetard : AppTheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Début: ${data['dateDebut']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(
                          179,
                        ),
                      ),
                    ),
                    Text(
                      'Fin: ${data['dateFin']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: isRetard
                            ? AppTheme.statusRetard.withAlpha(204)
                            : theme.colorScheme.onSurfaceVariant.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatBudget(double budget) {
    if (budget >= 1000000) {
      return '${(budget / 1000000).toStringAsFixed(1)}M${data['symbol'] ?? '€'}';
    }
    return '${(budget / 1000).toStringAsFixed(0)}K${data['symbol'] ?? '€'}';
  }

  String _shortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}. ${parts[1]}';
    return fullName;
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
