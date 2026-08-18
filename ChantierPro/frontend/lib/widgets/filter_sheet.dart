import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_state.dart';
import '../core/app_strings.dart';
import '../core/models/chantier.dart';
import '../core/utils/chantier_mapper.dart' show formatDate;
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════
// MODÈLES
// ═══════════════════════════════════════════════════

/// Filtre pour l'écran Chantiers.
class ChantierFilter {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? adresse;

  const ChantierFilter({this.dateFrom, this.dateTo, this.adresse});

  bool get isActive => dateFrom != null || dateTo != null ||
      (adresse != null && adresse!.isNotEmpty);

  ChantierFilter copyWith({
    Object? dateFrom = _sentinel,
    Object? dateTo = _sentinel,
    Object? adresse = _sentinel,
  }) =>
      ChantierFilter(
        dateFrom: dateFrom == _sentinel ? this.dateFrom : dateFrom as DateTime?,
        dateTo: dateTo == _sentinel ? this.dateTo : dateTo as DateTime?,
        adresse: adresse == _sentinel ? this.adresse : adresse as String?,
      );

  static const _sentinel = Object();
  ChantierFilter reset() => const ChantierFilter();
}

/// Filtre pour l'écran Tâches.
class TacheFilter {
  final int? chantierId;
  final String? chantierNom;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const TacheFilter({
    this.chantierId,
    this.chantierNom,
    this.dateFrom,
    this.dateTo,
  });

  bool get isActive => chantierId != null || dateFrom != null || dateTo != null;
  TacheFilter reset() => const TacheFilter();
}

/// Filtre pour l'écran Rapports.
class RapportFilter {
  final int? chantierId;
  final String? chantierNom;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const RapportFilter({
    this.chantierId,
    this.chantierNom,
    this.dateFrom,
    this.dateTo,
  });

  bool get isActive => chantierId != null || dateFrom != null || dateTo != null;
  RapportFilter reset() => const RapportFilter();
}

// ═══════════════════════════════════════════════════
// BOTTOM SHEET – CHANTIERS
// ═══════════════════════════════════════════════════

Future<ChantierFilter?> showChantierFilterSheet(
  BuildContext context, {
  required ChantierFilter current,
}) async {
  return showModalBottomSheet<ChantierFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ChantierFilterSheet(current: current),
  );
}

class _ChantierFilterSheet extends StatefulWidget {
  final ChantierFilter current;
  const _ChantierFilterSheet({required this.current});

  @override
  State<_ChantierFilterSheet> createState() => _ChantierFilterSheetState();
}

class _ChantierFilterSheetState extends State<_ChantierFilterSheet> {
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late TextEditingController _adresseCtrl;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.current.dateFrom;
    _dateTo = widget.current.dateTo;
    _adresseCtrl =
        TextEditingController(text: widget.current.adresse ?? '');
  }

  @override
  void dispose() {
    _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    return _FilterSheetWrapper(
      title: s('filter_chantiers'),
      onReset: () {
        setState(() {
          _dateFrom = null;
          _dateTo = null;
          _adresseCtrl.clear();
        });
      },
      onApply: () => Navigator.pop(
        context,
        ChantierFilter(
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          adresse: _adresseCtrl.text.trim().isEmpty
              ? null
              : _adresseCtrl.text.trim(),
        ),
      ),
      children: [
        _SectionTitle(s('period')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: s('date_start'),
                value: _dateFrom,
                onTap: () => _pickDate(true),
                onClear: () => setState(() => _dateFrom = null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: s('date_end'),
                value: _dateTo,
                onTap: () => _pickDate(false),
                onClear: () => setState(() => _dateTo = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionTitle(s('address')),
        const SizedBox(height: 10),
        TextField(
          controller: _adresseCtrl,
          decoration: InputDecoration(
            hintText: s('filter_address_hint'),
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            suffixIcon: _adresseCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => setState(() => _adresseCtrl.clear()),
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// BOTTOM SHEET – TÂCHES
// ═══════════════════════════════════════════════════

Future<TacheFilter?> showTacheFilterSheet(
  BuildContext context, {
  required TacheFilter current,
  required List<Chantier> chantiers,
}) async {
  return showModalBottomSheet<TacheFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        _TacheFilterSheet(current: current, chantiers: chantiers),
  );
}

class _TacheFilterSheet extends StatefulWidget {
  final TacheFilter current;
  final List<Chantier> chantiers;
  const _TacheFilterSheet({required this.current, required this.chantiers});

  @override
  State<_TacheFilterSheet> createState() => _TacheFilterSheetState();
}

class _TacheFilterSheetState extends State<_TacheFilterSheet> {
  late int? _chantierId;
  late String? _chantierNom;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _chantierId = widget.current.chantierId;
    _chantierNom = widget.current.chantierNom;
    _dateFrom = widget.current.dateFrom;
    _dateTo = widget.current.dateTo;
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
          _dateTo = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    return _FilterSheetWrapper(
      title: s('filter_tasks'),
      onReset: () => setState(() {
        _chantierId = null;
        _chantierNom = null;
        _dateFrom = null;
        _dateTo = null;
      }),
      onApply: () => Navigator.pop(
        context,
        TacheFilter(
          chantierId: _chantierId,
          chantierNom: _chantierNom,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        ),
      ),
      children: [
        _SectionTitle(s('chantier')),
        const SizedBox(height: 10),
        DropdownButtonFormField<int?>(
          value: _chantierId,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: s('all_chantiers'),
            prefixIcon:
                const Icon(Icons.construction_rounded, size: 20),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(s('all_chantiers'),
                  style:
                      GoogleFonts.plusJakartaSans(fontSize: 14)),
            ),
            ...widget.chantiers.map(
              (c) => DropdownMenuItem<int?>(
                value: c.id,
                child: Text(c.nom,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14)),
              ),
            ),
          ],
          onChanged: (v) => setState(() {
            _chantierId = v;
            _chantierNom = v == null
                ? null
                : widget.chantiers
                    .firstWhere((c) => c.id == v)
                    .nom;
          }),
        ),
        const SizedBox(height: 20),
        _SectionTitle(s('deadline')),
        const SizedBox(height: 10),
        _DateField(
          label: s('select_date'),
          value: _dateFrom,
          onTap: () => _pickDate(true),
          onClear: () => setState(() {
            _dateFrom = null;
            _dateTo = null;
          }),
          fullWidth: true,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// BOTTOM SHEET – RAPPORTS
// ═══════════════════════════════════════════════════

Future<RapportFilter?> showRapportFilterSheet(
  BuildContext context, {
  required RapportFilter current,
  required List<Chantier> chantiers,
}) async {
  return showModalBottomSheet<RapportFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        _RapportFilterSheet(current: current, chantiers: chantiers),
  );
}

class _RapportFilterSheet extends StatefulWidget {
  final RapportFilter current;
  final List<Chantier> chantiers;
  const _RapportFilterSheet(
      {required this.current, required this.chantiers});

  @override
  State<_RapportFilterSheet> createState() => _RapportFilterSheetState();
}

class _RapportFilterSheetState extends State<_RapportFilterSheet> {
  late int? _chantierId;
  late String? _chantierNom;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _chantierId = widget.current.chantierId;
    _chantierNom = widget.current.chantierNom;
    _dateFrom = widget.current.dateFrom;
    _dateTo = widget.current.dateTo;
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
          _dateTo = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    return _FilterSheetWrapper(
      title: s('filter_reports'),
      onReset: () => setState(() {
        _chantierId = null;
        _chantierNom = null;
        _dateFrom = null;
        _dateTo = null;
      }),
      onApply: () => Navigator.pop(
        context,
        RapportFilter(
          chantierId: _chantierId,
          chantierNom: _chantierNom,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        ),
      ),
      children: [
        _SectionTitle(s('chantier')),
        const SizedBox(height: 10),
        DropdownButtonFormField<int?>(
          value: _chantierId,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: s('all_chantiers'),
            prefixIcon:
                const Icon(Icons.construction_rounded, size: 20),
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(s('all_chantiers'),
                  style:
                      GoogleFonts.plusJakartaSans(fontSize: 14)),
            ),
            ...widget.chantiers.map(
              (c) => DropdownMenuItem<int?>(
                value: c.id,
                child: Text(c.nom,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14)),
              ),
            ),
          ],
          onChanged: (v) => setState(() {
            _chantierId = v;
            _chantierNom = v == null
                ? null
                : widget.chantiers
                    .firstWhere((c) => c.id == v)
                    .nom;
          }),
        ),
        const SizedBox(height: 20),
        _SectionTitle(s('report_date')),
        const SizedBox(height: 10),
        _DateField(
          label: s('select_date'),
          value: _dateFrom,
          onTap: () => _pickDate(true),
          onClear: () => setState(() {
            _dateFrom = null;
            _dateTo = null;
          }),
          fullWidth: true,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// BADGES DE FILTRES ACTIFS
// ═══════════════════════════════════════════════════

/// Affiche les filtres actifs sous forme de chips supprimables.
class ActiveFilterChips extends StatelessWidget {
  final List<_ActiveChip> chips;

  const ActiveFilterChips._({required this.chips});

  factory ActiveFilterChips.forChantier({
    required ChantierFilter filter,
    required VoidCallback onRemoveDateFrom,
    required VoidCallback onRemoveDateTo,
    required VoidCallback onRemoveAdresse,
  }) {
    final chips = <_ActiveChip>[];
    if (filter.dateFrom != null) {
      chips.add(_ActiveChip(
        icon: Icons.calendar_today_outlined,
        label: 'Dès ${formatDate(filter.dateFrom!)}',
        color: AppTheme.primary,
        onRemove: onRemoveDateFrom,
      ));
    }
    if (filter.dateTo != null) {
      chips.add(_ActiveChip(
        icon: Icons.calendar_today_outlined,
        label: 'Jusqu\'au ${formatDate(filter.dateTo!)}',
        color: AppTheme.primary,
        onRemove: onRemoveDateTo,
      ));
    }
    if (filter.adresse != null && filter.adresse!.isNotEmpty) {
      chips.add(_ActiveChip(
        icon: Icons.location_on_outlined,
        label: filter.adresse!,
        color: AppTheme.statusEnCours,
        onRemove: onRemoveAdresse,
      ));
    }
    return ActiveFilterChips._(chips: chips);
  }

  factory ActiveFilterChips.forTache({
    required TacheFilter filter,
    required VoidCallback onRemoveChantier,
    required VoidCallback onRemoveDate,
  }) {
    final chips = <_ActiveChip>[];
    if (filter.chantierNom != null) {
      chips.add(_ActiveChip(
        icon: Icons.construction_rounded,
        label: filter.chantierNom!,
        color: AppTheme.statusEnCours,
        onRemove: onRemoveChantier,
      ));
    }
    if (filter.dateFrom != null) {
      chips.add(_ActiveChip(
        icon: Icons.calendar_today_outlined,
        label: formatDate(filter.dateFrom!),
        color: AppTheme.primary,
        onRemove: onRemoveDate,
      ));
    }
    return ActiveFilterChips._(chips: chips);
  }

  factory ActiveFilterChips.forRapport({
    required RapportFilter filter,
    required VoidCallback onRemoveChantier,
    required VoidCallback onRemoveDate,
  }) {
    final chips = <_ActiveChip>[];
    if (filter.chantierNom != null) {
      chips.add(_ActiveChip(
        icon: Icons.construction_rounded,
        label: filter.chantierNom!,
        color: AppTheme.statusEnCours,
        onRemove: onRemoveChantier,
      ));
    }
    if (filter.dateFrom != null) {
      chips.add(_ActiveChip(
        icon: Icons.calendar_today_outlined,
        label: formatDate(filter.dateFrom!),
        color: AppTheme.primary,
        onRemove: onRemoveDate,
      ));
    }
    return ActiveFilterChips._(chips: chips);
  }

  bool get isEmpty => chips.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map(
                (chip) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: chip.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: chip.color.withAlpha(80), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(chip.icon, size: 13, color: chip.color),
                        const SizedBox(width: 5),
                        Text(
                          chip.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: chip.color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: chip.onRemove,
                          child: Icon(Icons.close_rounded,
                              size: 13, color: chip.color),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ActiveChip {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onRemove;
  const _ActiveChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onRemove});
}

// ═══════════════════════════════════════════════════
// ICÔNE FILTRE (AppBar)
// ═══════════════════════════════════════════════════

/// Icône dans l'AppBar avec badge rouge si un filtre est actif.
class FilterIconButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;

  const FilterIconButton(
      {super.key, required this.active, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        IconButton(
          onPressed: onPressed,
          tooltip: AppStrings.get(
              'filters', AppState().locale.languageCode),
          icon: Icon(
            Icons.tune_rounded,
            color: active ? AppTheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        if (active)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 9,
              height: 9,
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

// ═══════════════════════════════════════════════════
// WIDGETS INTERNES RÉUTILISABLES
// ═══════════════════════════════════════════════════

class _FilterSheetWrapper extends StatelessWidget {
  final String title;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final List<Widget> children;

  const _FilterSheetWrapper({
    required this.title,
    required this.onReset,
    required this.onApply,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poignée
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
            // Titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Contenu
            ...children,
            const SizedBox(height: 24),
            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(AppStrings.get(
                        'reset', lang)),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(AppStrings.get('apply', lang)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final bool fullWidth;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null;
    final widget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: hasValue
              ? AppTheme.primary.withAlpha(12)
              : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? AppTheme.primary
                : theme.colorScheme.outlineVariant,
            width: hasValue ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: hasValue
                  ? AppTheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    hasValue ? formatDate(value!) : '—',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasValue
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (hasValue)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
    return fullWidth ? widget : widget;
  }
}