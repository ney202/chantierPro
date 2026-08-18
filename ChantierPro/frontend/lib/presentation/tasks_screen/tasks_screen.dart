import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/api/auth_session.dart';
import '../../core/api/data_services.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';
import '../../core/models/chantier.dart';
import '../../core/models/tache.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_delete_button.dart';
import '../../widgets/app_bar_widget.dart';
import '../tache_detail_screen/tache_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _listAnimController;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  // ── Filtres avancés ──
  int? _filterChantierId;
  String? _filterPriorite;
  String? _filterCategorie;
  DateTime? _filterDateDebut;
  DateTime? _filterDateFin;

  bool _isLoading = true;
  String? _error;
  List<Tache> _taches = [];
  List<Chantier> _chantiers = [];

  bool get _isAdmin => AuthSession().user?.role == 'ADMIN';

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
      duration: const Duration(milliseconds: 700),
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
        TacheService().getAll(),
        ChantierService().getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _taches = (results[0] as List<Tache>)
          ..sort((a, b) => b.id.compareTo(a.id));
        _chantiers = results[1] as List<Chantier>;
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

  List<Tache> get _filteredTasks {
    var filtered = _searchQuery.isEmpty
        ? _taches
        : _taches.where((t) {
            final q = _normalizeText(_searchQuery);
            return _normalizeText(t.titre).contains(q) ||
                _normalizeText(t.chantierNom ?? '').contains(q) ||
                _normalizeText(t.description ?? '').contains(q);
          }).toList();

    if (_selectedFilter == 'suspendu') {
      filtered = filtered.where((t) => t.isSuspendue).toList();
    } else if (_selectedFilter != 'all') {
      filtered = filtered
          .where((t) => t.statut == _selectedFilter && !t.isSuspendue)
          .toList();
    }

    if (_filterChantierId != null) {
      filtered = filtered
          .where((t) => t.chantierId == _filterChantierId)
          .toList();
    }

    if (_filterPriorite != null) {
      filtered = filtered.where((t) => t.priorite == _filterPriorite).toList();
    }

    if (_filterCategorie != null) {
      filtered = filtered
          .where((t) => t.categorie == _filterCategorie)
          .toList();
    }

    if (_filterDateDebut != null) {
      filtered = filtered.where((t) {
        return t.dateDebut != null && !t.dateDebut!.isBefore(_filterDateDebut!);
      }).toList();
    }

    if (_filterDateFin != null) {
      filtered = filtered.where((t) {
        return t.dateFin != null && !t.dateFin!.isAfter(_filterDateFin!);
      }).toList();
    }

    return filtered;
  }

  bool get _hasAdvancedFilters =>
      _filterChantierId != null ||
      _filterPriorite != null ||
      _filterCategorie != null ||
      _filterDateDebut != null ||
      _filterDateFin != null;

  int _countForFilter(String key) {
    if (key == 'all') return _taches.length;
    if (key == 'suspendu') return _taches.where((t) => t.isSuspendue).length;
    return _taches.where((t) => t.statut == key && !t.isSuspendue).length;
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
        return Icons.check_circle_rounded;
      case 'suspendu':
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatDateYMD(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
      _filterChantierId = null;
      _filterPriorite = null;
      _filterCategorie = null;
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

    int? tempChantierId = _filterChantierId;
    String? tempPriorite = _filterPriorite;
    String? tempCategorie = _filterCategorie;
    DateTime? tempDateDebut = _filterDateDebut;
    DateTime? tempDateFin = _filterDateFin;

    final Map<String, String> priorites = {
      'faible': 'Faible',
      'normale': 'Normale',
      'elevee': 'Élevée',
      'critique': 'Critique',
    };

    final Map<String, String> categories = {
      'terrassement': 'Terrassement',
      'fondation': 'Fondation',
      'maconnerie': 'Maçonnerie',
      'beton': 'Béton',
      'electricite': 'Électricité',
      'plomberie': 'Plomberie',
      'menuiserie': 'Menuiserie',
      'peinture': 'Peinture',
      'finition': 'Finition',
      'autre': 'Autre',
    };

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
                          (c) =>
                              DropdownMenuItem(value: c.id, child: Text(c.nom)),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => tempChantierId = v),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String?>(
                      value: tempPriorite,
                      decoration: InputDecoration(
                        labelText: s('priority') ?? 'Priorité',
                        prefixIcon: Icon(
                          Icons.priority_high_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...priorites.entries.map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => tempPriorite = v),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String?>(
                      value: tempCategorie,
                      decoration: InputDecoration(
                        labelText: s('category') ?? 'Catégorie',
                        prefixIcon: Icon(
                          Icons.folder_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...categories.entries.map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => tempCategorie = v),
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
                        if (picked != null) {
                          setModalState(() => tempDateDebut = picked);
                        }
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
                        if (picked != null) {
                          setModalState(() => tempDateFin = picked);
                        }
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
                                tempChantierId = null;
                                tempPriorite = null;
                                tempCategorie = null;
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
                                _filterChantierId = tempChantierId;
                                _filterPriorite = tempPriorite;
                                _filterCategorie = tempCategorie;
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

  void _showAddTaskSheet(BuildContext context, String lang) {
    if (_chantiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.get('create_chantier_first', lang) ??
                'Créez d\'abord un chantier',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(
        lang: lang,
        chantiers: _chantiers,
        onCreated: _loadData,
      ),
    );
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState();
    final lang = appState.locale.languageCode;
    String s(String k) => AppStrings.get(k, lang) ?? k;
    final filtered = _filteredTasks;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppBarWidget(
            title: s('tasks'),
            showAvatar: false,
            subtitle:
                AppStrings.getP('tasks_total', lang, {
                  'n': '${_taches.length}',
                }) ??
                '${_taches.length} tâches',
          ),
          _buildSearchAndFilterBar(theme, lang, s),
          _buildFilterChips(theme),
          if (_hasAdvancedFilters) _buildActiveFilterChips(theme, lang, s),
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
                        const SizedBox(height: 120),
                        Icon(
                          Icons.task_outlined,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            s('no_tasks'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        final delay = index * 0.08;
                        final animation = Tween<double>(begin: 0, end: 1)
                            .animate(
                              CurvedAnimation(
                                parent: _listAnimController,
                                curve: Interval(
                                  delay.clamp(0.0, 0.8),
                                  (delay + 0.4).clamp(0.0, 1.0),
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                            );
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: _TaskCard(
                            task: task,
                            lang: lang,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TacheDetailScreen(tacheId: task.id),
                                ),
                              );
                              _loadData();
                            },
                            onDelete: _isAdmin
                                ? () async {
                                    try {
                                      await TacheService().delete(task.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Tâche supprimée'),
                                          ),
                                        );
                                        _loadData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
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
        onPressed: () => _showAddTaskSheet(context, lang),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          s('add_task'),
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
                hintText: s('search'),
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
              color: _hasAdvancedFilters
                  ? AppTheme.primary.withOpacity(0.12)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasAdvancedFilters
                    ? AppTheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: IconButton(
              onPressed: () => _showFilterSheet(context),
              icon: Icon(
                Icons.tune_rounded,
                color: _hasAdvancedFilters
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

    if (_filterChantierId != null) {
      String chantierNom = 'Chantier #$_filterChantierId';
      for (final c in _chantiers) {
        if (c.id == _filterChantierId) {
          chantierNom = c.nom;
          break;
        }
      }
      chips.add(
        _FilterChip(
          label: '${s('chantier')}: $chantierNom',
          onRemove: () {
            setState(() => _filterChantierId = null);
            _listAnimController.reset();
            _listAnimController.forward();
          },
        ),
      );
    }
    if (_filterPriorite != null) {
      final labels = {
        'faible': 'Faible',
        'normale': 'Normale',
        'elevee': 'Élevée',
        'critique': 'Critique',
      };
      chips.add(
        _FilterChip(
          label:
              '${s('priority')}: ${labels[_filterPriorite] ?? _filterPriorite}',
          onRemove: () {
            setState(() => _filterPriorite = null);
            _listAnimController.reset();
            _listAnimController.forward();
          },
        ),
      );
    }
    if (_filterCategorie != null) {
      final labels = {
        'terrassement': 'Terrassement',
        'fondation': 'Fondation',
        'maconnerie': 'Maçonnerie',
        'beton': 'Béton',
        'electricite': 'Électricité',
        'plomberie': 'Plomberie',
        'menuiserie': 'Menuiserie',
        'peinture': 'Peinture',
        'finition': 'Finition',
        'autre': 'Autre',
      };
      chips.add(
        _FilterChip(
          label:
              '${s('category')}: ${labels[_filterCategorie] ?? _filterCategorie}',
          onRemove: () {
            setState(() => _filterCategorie = null);
            _listAnimController.reset();
            _listAnimController.forward();
          },
        ),
      );
    }
    if (_filterDateDebut != null) {
      chips.add(
        _FilterChip(
          label: '${s('start_date')} ≥ ${_formatDate(_filterDateDebut)}',
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
          label: '${s('end_date')} ≤ ${_formatDate(_filterDateFin)}',
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

// ── Widgets internes ──

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

class _TaskCard extends StatelessWidget {
  final Tache task;
  final String lang;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TaskCard({
    required this.task,
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
        return Icons.check_circle_rounded;
      case 'suspendu':
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _priorityColor(String priorite, ThemeData theme) {
    switch (priorite) {
      case 'critique':
        return AppTheme.statusRetard;
      case 'elevee':
        return const Color(0xFFFF9800);
      case 'normale':
        return AppTheme.primary;
      case 'faible':
        return Colors.green;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(task.statut);
    final statusIcon = _statusIcon(task.statut);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: statusColor, width: 3)),
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.titre,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              task.chantierNom ?? '—',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              AppStrings.get(task.statut, lang) ?? task.statut,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          if (task.isSuspendue)
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
                      // ← BOUTON SUPPRESSION ADMIN
                      if (onDelete != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: AdminDeleteButton(onDelete: onDelete!),
                        ),
                    ],
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      task.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Badge(
                        text:
                            '${_formatDate(task.dateDebut)} → ${_formatDate(task.dateFin)}',
                        color: theme.colorScheme.onSurfaceVariant,
                        icon: Icons.calendar_today_outlined,
                      ),
                      if (task.priorite != null)
                        _Badge(
                          text: task.priorite!,
                          color: _priorityColor(task.priorite!, theme),
                          icon: Icons.flag_outlined,
                        ),
                      if (task.categorie != null)
                        _Badge(
                          text: task.categorie!,
                          color: AppTheme.primary,
                          icon: Icons.folder_outlined,
                        ),
                      if (task.avancement != null && task.avancement! > 0)
                        _Badge(
                          text: '${task.avancement}%',
                          color: AppTheme.statusEnCours,
                          icon: Icons.trending_up_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (task.avancement != null && task.avancement! > 0)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: LinearProgressIndicator(
                  value: (task.avancement! / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
          ],
        ),
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

// ── Ajout d'une tâche ──

class _AddTaskSheet extends StatefulWidget {
  final String lang;
  final List<Chantier> chantiers;
  final VoidCallback? onCreated;

  const _AddTaskSheet({
    required this.lang,
    required this.chantiers,
    this.onCreated,
  });

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TextEditingController _dateDebutController;
  late final TextEditingController _dateFinController;

  int? _selectedChantierId;
  String _selectedPriorite = 'normale';
  String _selectedCategorie = 'autre';
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  final List<String> _priorites = ['faible', 'normale', 'elevee', 'critique'];
  final List<String> _categories = [
    'terrassement',
    'fondation',
    'maconnerie',
    'beton',
    'electricite',
    'plomberie',
    'menuiserie',
    'peinture',
    'finition',
    'autre',
  ];

  @override
  void initState() {
    super.initState();
    _dateDebutController = TextEditingController(
      text: _formatDateYMD(_dateDebut),
    );
    _dateFinController = TextEditingController(text: _formatDateYMD(_dateFin));
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChantierId == null) return;

    setState(() => _isSaving = true);
    try {
      await TacheService().create(
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        chantierId: _selectedChantierId!,
        priorite: _selectedPriorite,
        categorie: _selectedCategorie,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.get('task_created', widget.lang) ?? 'Tâche créée',
            ),
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
    String s(String k) => AppStrings.get(k, widget.lang) ?? k;

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
                s('new_task'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: _selectedChantierId,
                decoration: InputDecoration(
                  labelText: '${s('chantier')} *',
                  prefixIcon: Icon(
                    Icons.construction_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                items: widget.chantiers
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.nom)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedChantierId = v),
                validator: (v) => v == null ? s('error_required') : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titreController,
                decoration: InputDecoration(
                  labelText: '${s('title')} *',
                  prefixIcon: Icon(
                    Icons.title_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s('error_required') : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: s('description'),
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriorite,
                      decoration: InputDecoration(
                        labelText: s('priority'),
                        prefixIcon: Icon(
                          Icons.flag_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      items: _priorites
                          .map(
                            (p) =>
                                DropdownMenuItem(value: p, child: Text(s(p))),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedPriorite = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategorie,
                      decoration: InputDecoration(
                        labelText: s('category'),
                        prefixIcon: Icon(
                          Icons.folder_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      items: _categories
                          .map(
                            (c) =>
                                DropdownMenuItem(value: c, child: Text(s(c))),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedCategorie = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: _dateDebutController,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateDebut,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateDebut = picked;
                            _dateDebutController.text = _formatDateYMD(
                              _dateDebut,
                            );
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: s('start_date'),
                        prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: _dateFinController,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateFin,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateFin = picked;
                            _dateFinController.text = _formatDateYMD(_dateFin);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: s('end_date'),
                        prefixIcon: Icon(
                          Icons.event_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
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

  String _formatDateYMD(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
