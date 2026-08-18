import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_state.dart';
import '../../../core/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';

class RecentChantiersWidget extends StatelessWidget {
  /// Liste de maps: {name, address, status, budget, progress}
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>)? onTap;

  const RecentChantiersWidget({super.key, this.items = const [], this.onTap});


  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      final theme = Theme.of(context);
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          AppStrings.get('no_chantier_yet', AppState().locale.languageCode),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      children: items
          .map((m) => GestureDetector(
                onTap: onTap != null ? () => onTap!(m) : null,
                child: _RecentChantierItem(data: m),
              ))
          .toList(),
    );
  }
}

class _RecentChantierItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RecentChantierItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ChantierStatusExt.fromString(data['status'] as String);
    final progress = data['progress'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == ChantierStatus.retard
              ? AppTheme.statusRetard.withAlpha(77)
              : theme.colorScheme.outlineVariant,
          width: status == ChantierStatus.retard ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
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
              const SizedBox(width: 8),
              StatusBadgeWidget(status: status, compact: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['budgetLabel'] as String? ?? '${data['budget']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                status == ChantierStatus.retard
                    ? AppTheme.statusRetard
                    : AppTheme.primary,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
