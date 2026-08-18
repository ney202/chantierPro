import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_state.dart';
import '../core/app_strings.dart';
import '../core/utils/chantier_mapper.dart' show formatDate;
import '../theme/app_theme.dart';

/// Résultat du panneau de filtres par période.
class DateFilterResult {
  final DateTime? from;
  final DateTime? to;
  const DateFilterResult({this.from, this.to});
  bool get isActive => from != null || to != null;
}

/// Icône de filtre à placer dans une AppBar : ouvre le panneau de
/// période et affiche un point rouge quand un filtre est actif.
class FilterIconButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;

  const FilterIconButton({
    super.key,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: AppStrings.get('filters', AppState().locale.languageCode),
          icon: Icon(
            Icons.tune_rounded,
            color: active ? AppTheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        if (active)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.statusRetard,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// Panneau de filtres par période (Du / Au), style professionnel :
/// bottom sheet avec Réinitialiser et Appliquer.
/// Retourne null si l'utilisateur annule (fermeture sans appliquer).
Future<DateFilterResult?> showDateFilterSheet(
  BuildContext context, {
  DateTime? from,
  DateTime? to,

  /// true = une seule date (tâches, rapports) ;
  /// false = plage Du/Au (chantiers : date de début -> date de fin).
  bool singleDate = false,
}) {
  final lang = AppState().locale.languageCode;
  String s(String k) => AppStrings.get(k, lang);

  return showModalBottomSheet<DateFilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      DateTime? localFrom = from;
      DateTime? localTo = to;
      final theme = Theme.of(ctx);

      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          Widget dateField({
            required String label,
            required DateTime? value,
            required ValueChanged<DateTime?> onChanged,
          }) {
            return Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: value ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setSheetState(() => onChanged(picked));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                      120,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: value != null
                          ? AppTheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: value != null
                                ? AppTheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            value != null ? formatDate(value) : '—',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: value != null
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s('filters'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  singleDate ? s('filter_by_day') : s('filter_period'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    dateField(
                      label: singleDate ? s('date') : s('from'),
                      value: localFrom,
                      onChanged: (d) {
                        localFrom = d;
                        // En mode date unique, la borne haute = la même date.
                        if (singleDate) localTo = d;
                      },
                    ),
                    if (!singleDate) ...[
                      const SizedBox(width: 10),
                      dateField(
                        label: s('to'),
                        value: localTo,
                        onChanged: (d) => localTo = d,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(ctx, const DateFilterResult()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(s('reset')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(
                          ctx,
                          DateFilterResult(from: localFrom, to: localTo),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(s('apply')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Teste si [date] ('yyyy-MM-dd' ou DateTime) est dans [from, to].
bool dateInRange(dynamic date, DateTime? from, DateTime? to) {
  if (from == null && to == null) return true;
  DateTime? d;
  if (date is DateTime) {
    d = date;
  } else if (date is String) {
    d = DateTime.tryParse(date);
  }
  if (d == null) return false;
  if (from != null && d.isBefore(DateTime(from.year, from.month, from.day))) {
    return false;
  }
  if (to != null &&
      d.isAfter(DateTime(to.year, to.month, to.day, 23, 59, 59))) {
    return false;
  }
  return true;
}
