import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/api/auth_session.dart';
import '../../core/api/data_services.dart';
import '../../core/models/chantier.dart';
import '../../core/models/depense.dart';
import '../../core/models/tache.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_delete_button.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/empty_state_widget.dart';
import './widgets/add_chantier_bottom_sheet.dart';
import '../chantier_detail_screen/chantier_detail_screen.dart';

class ChantiersListScreen extends StatefulWidget {
  const ChantiersListScreen({super.key});
  @override
  State<ChantiersListScreen> createState() => _ChantiersListScreenState();
}

class _ChantiersListScreenState extends State<ChantiersListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isLoading = true;
  late AnimationController _listAnimController;
  List<Chantier> _chantiers = [];
  List<Tache> _taches = [];
  List<Depense> _depenses = [];
  String? _error;
  String? _filterAdresse;
  DateTime? _filterDateDebut;
  DateTime? _filterDateFin;

  bool get _isAdmin => AuthSession().user?.role == 'ADMIN';

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

  List<Map<String, dynamic>> get _chantierMaps => _chantiers.map((c) {
    final relatedTaches = _taches.where((t) => t.chantierId == c.id).toList();
    final terminees = relatedTaches.where((t) => t.statut == 'termine').length;
    final total = relatedTaches.length;
    return {
      'id': c.id,
      'name': c.nom,
      'address': c.localisation,
      'status': c.statut,
      'dateDebut': c.dateDebut != null ? _formatDate(c.dateDebut!) : null,
      'dateFin': c.dateFinPrevue != null ? _formatDate(c.dateFinPrevue!) : null,
      'dateDebutRaw': c.dateDebut,
      'dateFinPrevueRaw': c.dateFinPrevue,
      'budget': c.budget,
      'symbol': c.symbol,
      'devise': c.devise,
      'progress': c.avancement / 100.0,
      'avancement': c.avancement,
      'description': c.description,
      'client': c.client,
      'chefChantier': c.chefNom,
      'chefId': c.chefId,
      'suspendu': c.suspendu,
      'canDemarrer': c.canDemarrer,
      'canTerminer': c.canTerminer,
      'isEnRetard': c.isEnRetard,
      'joursRetard': c.joursRetard,
      'isAttention': c.isAttention,
      'nbTachesTotal': c.nbTachesTotal,
      'nbTachesTerminees': c.nbTachesTerminees,
      'nbTachesEnCours': c.nbTachesEnCours,
      'nbTachesPlanifiees': c.nbTachesPlanifiees,
      'nbTachesRetard': c.nbTachesRetard,
      'tachesTerminees': terminees,
      'nbTaches': total,
      // === V2 : Coordonnées GPS ===
      'latitude': c.latitude,
      'longitude': c.longitude,
      'adresseComplete': c.adresseComplete,
      // =============================
    };
  }).toList();

  List<Map<String, dynamic>> get _filtered {
    return _chantierMaps.where((m) {
      final name = _normalizeText(m['name'] as String? ?? '');
      final address = _normalizeText(m['address'] as String? ?? '');
      final query = _normalizeText(_searchQuery);
      final matchSearch =
          _searchQuery.isEmpty ||
          name.contains(query) ||
          address.contains(query);
      bool matchFilter = true;
      if (_selectedFilter == 'suspendu') {
        matchFilter = m['suspendu'] == true;
      } else if (_selectedFilter != 'all') {
        matchFilter = m['status'] == _selectedFilter && m['suspendu'] != true;
      }
      bool matchAdresse = true;
      if (_filterAdresse != null && _filterAdresse!.isNotEmpty) {
        matchAdresse = address.contains(_normalizeText(_filterAdresse!));
      }
      bool matchDateDebut = true;
      if (_filterDateDebut != null) {
        final raw = m['dateDebutRaw'] as DateTime?;
        matchDateDebut = raw != null && !raw.isBefore(_filterDateDebut!);
      }
      bool matchDateFin = true;
      if (_filterDateFin != null) {
        final raw = m['dateFinPrevueRaw'] as DateTime?;
        matchDateFin = raw != null && !raw.isAfter(_filterDateFin!);
      }
      return matchSearch &&
          matchFilter &&
          matchAdresse &&
          matchDateDebut &&
          matchDateFin;
    }).toList();
  }

  bool get _hasActiveFilters =>
      (_filterAdresse != null && _filterAdresse!.isNotEmpty) ||
      _filterDateDebut != null ||
      _filterDateFin != null;

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _formatDateYMD(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static const List<String> _filterKeys = [
    'all',
    'en_cours',
    'planifie',
    'retard',
    'attention',
    'termine',
    'suspendu',
  ];

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ChantierService().getAll(),
        TacheService().getAll(),
        DepenseService().getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _chantiers = results[0] as List<Chantier>;
        _taches = results[1] as List<Tache>;
        _depenses = results[2] as List<Depense>;
        _isLoading = false;
      });
      _listAnimController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = ApiClient.errorMessage(e);
      });
    }
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _listAnimController.reset();
    _listAnimController.forward();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _listAnimController.reset();
    _listAnimController.forward();
  }

  void _clearAdvancedFilters() {
    setState(() {
      _filterAdresse = null;
      _filterDateDebut = null;
      _filterDateFin = null;
    });
    _listAnimController.reset();
    _listAnimController.forward();
  }

  void _showFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    String tempAdresse = _filterAdresse ?? '';
    DateTime? tempDateDebut = _filterDateDebut;
    DateTime? tempDateFin = _filterDateFin;

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
                    TextFormField(
                      initialValue: tempAdresse,
                      onChanged: (v) => tempAdresse = v,
                      decoration: InputDecoration(
                        labelText: s('address') ?? 'Adresse',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _formatDateYMD(tempDateDebut),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx2,
                          initialDate: tempDateDebut ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null)
                          setModalState(() => tempDateDebut = picked);
                      },
                      decoration: InputDecoration(
                        labelText: s('start_date') ?? 'Date début',
                        prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        suffixIcon: tempDateDebut != null
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () =>
                                    setModalState(() => tempDateDebut = null),
                              )
                            : const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _formatDateYMD(tempDateFin),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx2,
                          initialDate: tempDateFin ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null)
                          setModalState(() => tempDateFin = picked);
                      },
                      decoration: InputDecoration(
                        labelText: s('end_date') ?? 'Date fin',
                        prefixIcon: Icon(
                          Icons.event_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        suffixIcon: tempDateFin != null
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () =>
                                    setModalState(() => tempDateFin = null),
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
                                tempAdresse = '';
                                tempDateDebut = null;
                                tempDateFin = null;
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
                                _filterAdresse = tempAdresse.isEmpty
                                    ? null
                                    : tempAdresse;
                                _filterDateDebut = tempDateDebut;
                                _filterDateFin = tempDateFin;
                              });
                              _listAnimController.reset();
                              _listAnimController.forward();
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

  Future<void> _onRefresh() => _loadData();
  void _showAddChantierSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddChantierBottomSheet(onCreated: _loadData),
    );
  }

  int _countForFilter(String key) {
    if (key == 'all') return _chantierMaps.length;
    if (key == 'suspendu')
      return _chantierMaps.where((m) => m['suspendu'] == true).length;
    return _chantierMaps
        .where((m) => m['status'] == key && m['suspendu'] != true)
        .length;
  }

  Color _filterColor(String key) {
    switch (key) {
      case 'en_cours':
        return AppTheme.statusEnCours;
      case 'planifie':
        return AppTheme.statusPlanifie;
      case 'retard':
        return AppTheme.statusRetard;
      case 'attention':
        return const Color(0xFFFF9800);
      case 'termine':
        return AppTheme.statusTermine;
      case 'suspendu':
        return Colors.grey;
      default:
        return AppTheme.primary;
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
            title: s('chantiers'),
            showAvatar: false,
            subtitle: AppStrings.getP('projects_total', lang, {
              'n': '${_chantierMaps.length}',
            }),
          ),
          _buildSearchAndFilterBar(theme, lang, s),
          _buildFilterChips(theme),
          if (_hasActiveFilters) _buildActiveFilterChips(theme, lang, s),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
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
                  ? EmptyStateWidget(
                      icon: Icons.construction_outlined,
                      title: s('no_chantier_found'),
                      description: _searchQuery.isNotEmpty
                          ? AppStrings.getP('no_result_for', lang, {
                              'q': _searchQuery,
                            })
                          : s('no_status_match'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: filtered.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final delay = (index * 0.08).clamp(0.0, 0.8);
                        final end = (delay + 0.4).clamp(0.0, 1.0);
                        final anim = CurvedAnimation(
                          parent: _listAnimController,
                          curve: Interval(
                            delay,
                            end,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                        return AnimatedBuilder(
                          animation: anim,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.12),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: child,
                              ),
                            );
                          },
                          child: _ChantierCard(
                            data: filtered[index],
                            lang: lang,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChantierDetailScreen(
                                    chantier: filtered[index],
                                  ),
                                ),
                              );
                              _loadData();
                            },
                            onDelete: _isAdmin
                                ? () async {
                                    try {
                                      final id = filtered[index]['id'] as int;
                                      await ChantierService().delete(id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Chantier supprimé'),
                                          ),
                                        );
                                        _loadData();
                                      }
                                    } catch (e) {
                                      if (mounted)
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              ApiClient.errorMessage(e),
                                            ),
                                          ),
                                        );
                                    }
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChantierSheet,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          s('new_chantier'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchAndFilterBar(
    ThemeData theme,
    String lang,
    String Function(String) s,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppStrings.get(
                  'search',
                  AppState().locale.languageCode,
                ),
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
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
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

  Widget _buildFilterChips(ThemeData theme) {
    final lang = AppState().locale.languageCode;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filterKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filterKeys[index];
          final isSelected = _selectedFilter == filter;
          final color = _filterColor(filter);
          final count = _countForFilter(filter);
          return GestureDetector(
            onTap: () => _onFilterChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.12)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.get(filter, lang) ?? filter,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? color
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilterChips(
    ThemeData theme,
    String lang,
    String Function(String) s,
  ) {
    final chips = <Widget>[];
    if (_filterAdresse != null && _filterAdresse!.isNotEmpty) {
      chips.add(
        _FilterChip(
          label: '${s('address') ?? 'Adresse'}: $_filterAdresse',
          onRemove: () {
            setState(() => _filterAdresse = null);
            _listAnimController.reset();
            _listAnimController.forward();
          },
        ),
      );
    }
    if (_filterDateDebut != null) {
      chips.add(
        _FilterChip(
          label:
              '${s('start_date') ?? 'Début'} ≥ ${_formatDate(_filterDateDebut!)}',
          onRemove: () {
            setState(() => _filterDateDebut = null);
            _listAnimController.reset();
            _listAnimController.forward();
          },
        ),
      );
    }
    if (_filterDateFin != null) {
      chips.add(
        _FilterChip(
          label: '${s('end_date') ?? 'Fin'} ≤ ${_formatDate(_filterDateFin!)}',
          onRemove: () {
            setState(() => _filterDateFin = null);
            _listAnimController.reset();
            _listAnimController.forward();
          },
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

// ============================================================================
// CARTE DE CHANTIER
// ============================================================================

class _ChantierCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String lang;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const _ChantierCard({
    required this.data,
    required this.lang,
    this.onTap,
    this.onDelete,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'en_cours':
        return AppTheme.statusEnCours;
      case 'planifie':
        return AppTheme.statusPlanifie;
      case 'retard':
        return AppTheme.statusRetard;
      case 'attention':
        return const Color(0xFFFF9800);
      case 'termine':
        return AppTheme.statusTermine;
      case 'suspendu':
        return Colors.grey;
      default:
        return AppTheme.primary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'en_cours':
        return Icons.play_circle_outline_rounded;
      case 'planifie':
        return Icons.schedule_rounded;
      case 'retard':
        return Icons.warning_amber_rounded;
      case 'attention':
        return Icons.notification_important_rounded;
      case 'termine':
        return Icons.check_circle_outline_rounded;
      case 'suspendu':
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.business_outlined;
    }
  }

  String _fmtDate(dynamic d) {
    if (d == null) return '—';
    if (d is String && (d == '—' || d.isEmpty)) return '—';
    if (d is String) return d;
    if (d is DateTime)
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '—';
  }

  String _safeString(dynamic value) => (value as String?) ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _safeString(data['status']).isNotEmpty
        ? data['status'] as String
        : 'planifie';
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    final progress = ((data['progress'] as num?)?.toDouble() ?? 0.0).clamp(
      0.0,
      1.0,
    );
    final name = _safeString(data['name']);
    final address = _safeString(data['address']);
    final budget = (data['budget'] as num?)?.toDouble() ?? 0.0;
    final symbol = _safeString(data['symbol']).isNotEmpty
        ? data['symbol'] as String
        : '€';
    final nbTachesTotal = (data['nbTachesTotal'] as num?)?.toInt() ?? 0;
    final nbTachesTerminees = (data['nbTachesTerminees'] as num?)?.toInt() ?? 0;
    final isSuspendu = data['suspendu'] == true;
    final isEnRetard = data['isEnRetard'] == true;
    final joursRetard = (data['joursRetard'] as num?)?.toInt() ?? 0;
    final isAttention = data['isAttention'] == true;
    final hasCoords = data['latitude'] != null && data['longitude'] != null;
    final statusLabel = AppStrings.get(status, lang) ?? status;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (hasCoords)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      color: AppTheme.primary,
                                      size: 12,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    address.isNotEmpty ? address : '—',
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          if (isSuspendu)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  AppStrings.get('suspendu', lang) ??
                                      'Suspendu',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (onDelete != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: AdminDeleteButton(onDelete: onDelete!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (isEnRetard && joursRetard > 0)
                        _Badge(
                          text: '+$joursRetard j',
                          color: AppTheme.statusRetard,
                          icon: Icons.warning_amber_outlined,
                        ),
                      if (isAttention)
                        _Badge(
                          text:
                              AppStrings.get('attention', lang) ?? 'Attention',
                          color: const Color(0xFFFF9800),
                          icon: Icons.notification_important_outlined,
                        ),
                      _Badge(
                        text: '$nbTachesTerminees/$nbTachesTotal tâches',
                        color: theme.colorScheme.onSurfaceVariant,
                        icon: Icons.folder_outlined,
                      ),
                      _Badge(
                        text: '${budget.toStringAsFixed(0)} $symbol',
                        color: AppTheme.primary,
                        icon: Icons.euro_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_fmtDate(data['dateDebut'])} → ${_fmtDate(data['dateFin'])}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (progress > 0 || status == 'en_cours' || status == 'planifie')
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _Badge({required this.text, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
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
