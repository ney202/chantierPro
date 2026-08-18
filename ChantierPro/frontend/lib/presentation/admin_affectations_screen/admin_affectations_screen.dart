import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/admin_services.dart';
import '../../core/api/api_client.dart';
import '../../core/api/data_services.dart';
import '../../core/api/refresh_bus.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';
import '../../core/models/affectation.dart';
import '../../core/models/chantier.dart';
import '../../core/models/utilisateur.dart';
import '../../core/utils/chantier_mapper.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';

/// Écran ADMIN : affectation des chefs de chantier aux chantiers.
/// Utilise /api/affectations (POST/DELETE réservés ADMIN).
class AdminAffectationsScreen extends StatefulWidget {
  const AdminAffectationsScreen({super.key});

  @override
  State<AdminAffectationsScreen> createState() =>
      _AdminAffectationsScreenState();
}

class _AdminAffectationsScreenState extends State<AdminAffectationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Affectation> _affectations = [];
  List<Chantier> _chantiers = [];
  List<Utilisateur> _chefs = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ── Filtres avancés ──
  int? _filterChantierId;
  int? _filterChefId;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AffectationService().getAll(),
        ChantierService().getAll(),
        UtilisateurAdminService().getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _affectations = (results[0] as List<Affectation>)
          ..sort((a, b) => b.id.compareTo(a.id));
        _chantiers = results[1] as List<Chantier>;
        _chefs = (results[2] as List<Utilisateur>)
            .where((u) => u.role == 'CHEF_CHANTIER')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = ApiClient.errorMessage(e);
      });
    }
  }

  String _normalizeText(String text) {
    const accents = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'ç': 'c',
      'ñ': 'n',
    };
    return text.toLowerCase().split('').map((c) => accents[c] ?? c).join();
  }

  List<Affectation> get _filtered {
    var filtered = _affectations;

    // ── Recherche rapide (barre) ──
    if (_searchQuery.isNotEmpty) {
      final q = _normalizeText(_searchQuery);
      filtered = filtered.where((a) {
        return _normalizeText(_chefNom(a.utilisateurId)).contains(q) ||
            _normalizeText(_chantierNom(a.chantierId)).contains(q);
      }).toList();
    }

    // ── Filtre avancé : chantier ──
    if (_filterChantierId != null) {
      filtered = filtered
          .where((a) => a.chantierId == _filterChantierId)
          .toList();
    }

    // ── Filtre avancé : chef ──
    if (_filterChefId != null) {
      filtered = filtered
          .where((a) => a.utilisateurId == _filterChefId)
          .toList();
    }

    // ── Filtre avancé : date ──
    if (_filterDate != null) {
      filtered = filtered.where((a) {
        if (a.dateAffectation == null) return false;
        return a.dateAffectation!.year == _filterDate!.year &&
            a.dateAffectation!.month == _filterDate!.month &&
            a.dateAffectation!.day == _filterDate!.day;
      }).toList();
    }

    return filtered;
  }

  bool get _hasActiveFilters =>
      _filterChantierId != null || _filterChefId != null || _filterDate != null;

  void _clearAdvancedFilters() {
    setState(() {
      _filterChantierId = null;
      _filterChefId = null;
      _filterDate = null;
    });
  }

  String _chantierNom(int? id) {
    for (final c in _chantiers) {
      if (c.id == id) return c.nom;
    }
    return 'Chantier #$id';
  }

  String _chefNom(int? id) {
    for (final u in _chefs) {
      if (u.id == id) return u.nom;
    }
    return 'Utilisateur #$id';
  }

  String _formatDateYMD(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _showFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);

    int? tempChantierId = _filterChantierId;
    int? tempChefId = _filterChefId;
    DateTime? tempDate = _filterDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
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
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 20),
                    Text(
                      s('filters') ?? 'Filtres',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int?>(
                      value: tempChantierId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: s('chantier') ?? 'Chantier',
                        prefixIcon: Icon(
                          Icons.construction_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ..._chantiers.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nom, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => tempChantierId = v),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int?>(
                      value: tempChefId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: s('chef_chantier') ?? 'Chef de chantier',
                        prefixIcon: Icon(
                          Icons.engineering_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ..._chefs.map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.nom, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => tempChefId = v),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _formatDateYMD(tempDate),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx2,
                          initialDate: tempDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() => tempDate = picked);
                        }
                      },
                      decoration: InputDecoration(
                        labelText:
                            s('assignment_date') ?? 'Date d\'affectation',
                        prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        suffixIcon: tempDate != null
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () =>
                                    setModalState(() => tempDate = null),
                              )
                            : const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempChantierId = null;
                                tempChefId = null;
                                tempDate = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(s('reset') ?? 'Réinitialiser'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _filterChantierId = tempChantierId;
                                _filterChefId = tempChefId;
                                _filterDate = tempDate;
                              });
                              Navigator.pop(ctx);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(s('apply') ?? 'Appliquer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSheet() {
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    if (_chantiers.isEmpty || _chefs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s('need_chef_and_chantier')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AffectationFormSheet(
        chantiers: _chantiers,
        chefs: _chefs,
        existing: _affectations,
        onSaved: () {
          RefreshBus().ping();
          _loadData();
        },
      ),
    );
  }

  Future<void> _confirmDelete(Affectation a) async {
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s('confirm_delete')),
        content: Text(s('delete_assignment_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(s('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AffectationService().delete(a.id);
      RefreshBus().ping();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s('assignment_deleted')),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.errorMessage(e)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppBarWidget(
            title: s('assignments'),
            subtitle: '${filtered.length} ${s('in_total')}',
            showBack: true,
            showAvatar: false,
          ),
          _buildSearchAndFilterBar(theme, lang, s),
          if (_hasActiveFilters) _buildActiveFilterChips(theme, lang, s),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(32),
                      children: [
                        const SizedBox(height: 60),
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: FilledButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(s('retry')),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          Icons.assignment_ind_outlined,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            s('no_assignments'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final a = filtered[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(31),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.assignment_ind_rounded,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _chefNom(a.utilisateurId),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_chantierNom(a.chantierId)} · ${a.dateAffectation != null ? formatDate(a.dateAffectation!) : '—'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: AppTheme.error,
                                ),
                                onPressed: () => _confirmDelete(a),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          s('new_assignment'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(
    ThemeData theme,
    String lang,
    String Function(String) s,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: s('search') ?? 'Rechercher…',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _hasActiveFilters
                  ? AppTheme.primary.withOpacity(0.12)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasActiveFilters
                    ? AppTheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: IconButton(
              onPressed: () => _showFilterSheet(context),
              icon: Icon(
                Icons.tune_rounded,
                color: _hasActiveFilters
                    ? AppTheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(
    ThemeData theme,
    String lang,
    String Function(String) s,
  ) {
    final chips = <Widget>[];

    if (_filterChantierId != null) {
      chips.add(
        _FilterChip(
          label:
              '${s('chantier') ?? 'Chantier'}: ${_chantierNom(_filterChantierId)}',
          onRemove: () => setState(() => _filterChantierId = null),
        ),
      );
    }
    if (_filterChefId != null) {
      chips.add(
        _FilterChip(
          label: '${s('chef_chantier') ?? 'Chef'}: ${_chefNom(_filterChefId)}',
          onRemove: () => setState(() => _filterChefId = null),
        ),
      );
    }
    if (_filterDate != null) {
      chips.add(
        _FilterChip(
          label: '${s('date') ?? 'Date'}: ${formatDate(_filterDate!)}',
          onRemove: () => setState(() => _filterDate = null),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

// ── Chip de filtre actif ──
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _AffectationFormSheet extends StatefulWidget {
  final List<Chantier> chantiers;
  final List<Utilisateur> chefs;
  final List<Affectation> existing;
  final VoidCallback onSaved;

  const _AffectationFormSheet({
    required this.chantiers,
    required this.chefs,
    required this.existing,
    required this.onSaved,
  });

  @override
  State<_AffectationFormSheet> createState() => _AffectationFormSheetState();
}

class _AffectationFormSheetState extends State<_AffectationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _chantierId;
  int? _chefId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  Future<void> _submit() async {
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    if (!_formKey.currentState!.validate()) return;

    // Anti-doublon : même chef déjà affecté au même chantier.
    final duplicate = widget.existing.any(
      (a) => a.utilisateurId == _chefId && a.chantierId == _chantierId,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s('duplicate_assignment')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AffectationService().create(
        utilisateurId: _chefId!,
        chantierId: _chantierId!,
        dateAffectation: _date,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s('assignment_created')),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.errorMessage(e)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              Text(
                s('new_assignment'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: _chantierId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: '${s('select_chantier')} *',
                  prefixIcon: Icon(
                    Icons.construction_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                items: widget.chantiers
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nom, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _chantierId = v),
                validator: (v) => v == null ? s('error_required') : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _chefId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: '${s('chef_chantier')} *',
                  prefixIcon: Icon(
                    Icons.engineering_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                items: widget.chefs
                    .map(
                      (u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(u.nom, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _chefId = v),
                validator: (v) => v == null ? s('error_required') : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: formatDate(_date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                decoration: InputDecoration(
                  labelText: '${s('assignment_date')} *',
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  suffixIcon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        s('save'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
