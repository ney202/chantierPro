import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/api/auth_session.dart';
import '../../core/api/data_services.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';
import '../../core/models/chantier.dart';
import '../../core/models/photo.dart';
import '../../core/models/rapport.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_delete_button.dart'; // ← AJOUTÉ
import '../../widgets/app_bar_widget.dart';

const List<String> kReportTypes = [
  'daily',
  'monthly',
  'inspection',
  'incident',
  'meeting',
  'closure',
];

({String type, String content}) parseReportContent(String raw) {
  final match = RegExp(r'^\[(\w+)\]\s*').firstMatch(raw);
  if (match != null && kReportTypes.contains(match.group(1))) {
    return (type: match.group(1)!, content: raw.substring(match.end));
  }
  return (type: 'daily', content: raw);
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _listAnimController;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  // ── Filtres avancés ──
  int? _filterChantierId;
  String? _filterType;
  DateTime? _filterDate;

  bool _isLoading = true;
  String? _error;
  List<Rapport> _rapports = [];
  List<Chantier> _chantiers = [];
  Map<int, List<Photo>> _photosByRapport = {};

  bool get _isAdmin => AuthSession().user?.role == 'ADMIN'; // ← AJOUTÉ

  static const List<String> _filterKeys = [
    'all',
    'daily',
    'monthly',
    'inspection',
    'incident',
    'meeting',
    'closure',
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
        RapportService().getAll(),
        ChantierService().getAll(),
        PhotoService().getAll(),
      ]);
      if (!mounted) return;
      final photos = results[2] as List<Photo>;
      final byRapport = <int, List<Photo>>{};
      for (final p in photos) {
        if (p.rapportId != null) {
          byRapport.putIfAbsent(p.rapportId!, () => []).add(p);
        }
      }
      setState(() {
        _rapports = (results[0] as List<Rapport>)
          ..sort((a, b) => b.id.compareTo(a.id));
        _chantiers = results[1] as List<Chantier>;
        _photosByRapport = byRapport;
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

  List<Map<String, dynamic>> get _filteredReports {
    final list = _rapports.map((r) {
      final parsed = parseReportContent(r.contenu);
      return {
        'rapport': r,
        'type': parsed.type,
        'content': parsed.content,
        'chantierNom': _chantierNom(r.chantierId),
        'author': _authorLabel(r.auteurId),
        'date': r.dateRapport != null ? _formatDate(r.dateRapport!) : '—',
        'photos': _photosByRapport[r.id] ?? <Photo>[],
      };
    }).toList();

    var filtered = _searchQuery.isEmpty
        ? list
        : list.where((r) {
            final q = _normalizeText(_searchQuery);
            return _normalizeText(r['content'] as String).contains(q) ||
                _normalizeText(r['chantierNom'] as String).contains(q) ||
                _normalizeText(r['author'] as String).contains(q);
          }).toList();

    if (_selectedFilter != 'all') {
      filtered = filtered.where((r) => r['type'] == _selectedFilter).toList();
    }

    if (_filterChantierId != null) {
      filtered = filtered.where((r) {
        final rapport = r['rapport'] as Rapport;
        return rapport.chantierId == _filterChantierId;
      }).toList();
    }

    if (_filterType != null) {
      filtered = filtered.where((r) => r['type'] == _filterType).toList();
    }

    if (_filterDate != null) {
      filtered = filtered.where((r) {
        final rapport = r['rapport'] as Rapport;
        if (rapport.dateRapport == null) return false;
        return rapport.dateRapport!.year == _filterDate!.year &&
            rapport.dateRapport!.month == _filterDate!.month &&
            rapport.dateRapport!.day == _filterDate!.day;
      }).toList();
    }

    return filtered;
  }

  bool get _hasAdvancedFilters =>
      _filterChantierId != null || _filterType != null || _filterDate != null;

  String _chantierNom(int? id) {
    if (id == null) return '—';
    for (final c in _chantiers) {
      if (c.id == id) return c.nom;
    }
    return 'Chantier #$id';
  }

  String _authorLabel(int? auteurId) {
    final me = AuthSession().user;
    if (auteurId != null && me != null && auteurId == me.id) return me.nom;
    if (auteurId == null) return '—';
    return 'Auteur #$auteurId';
  }

  int _countForFilter(String key) {
    if (key == 'all') return _rapports.length;
    return _rapports.where((r) {
      final parsed = parseReportContent(r.contenu);
      return parsed.type == key;
    }).length;
  }

  Color _filterColor(String key) {
    switch (key) {
      case 'daily':
        return AppTheme.statusEnCours;
      case 'monthly':
        return AppTheme.statusPlanifie;
      case 'inspection':
        return AppTheme.info;
      case 'incident':
        return AppTheme.statusRetard;
      case 'meeting':
        return AppTheme.statusEnAttente;
      case 'closure':
        return AppTheme.statusTermine;
      default:
        return AppTheme.primary;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'daily':
        return AppTheme.statusEnCours;
      case 'monthly':
        return AppTheme.statusPlanifie;
      case 'inspection':
        return AppTheme.info;
      case 'incident':
        return AppTheme.statusRetard;
      case 'meeting':
        return AppTheme.statusEnAttente;
      case 'closure':
        return AppTheme.statusTermine;
      default:
        return AppTheme.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'daily':
        return Icons.today_rounded;
      case 'monthly':
        return Icons.calendar_month_rounded;
      case 'inspection':
        return Icons.search_rounded;
      case 'incident':
        return Icons.warning_amber_rounded;
      case 'meeting':
        return Icons.groups_rounded;
      case 'closure':
        return Icons.check_circle_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  String _formatDate(DateTime d) {
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
      _filterType = null;
      _filterDate = null;
    });
    _listAnimController.reset();
    _listAnimController.forward();
  }

  void _showFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);

    int? tempChantierId = _filterChantierId;
    String? tempType = _filterType;
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
                      value: tempType,
                      decoration: InputDecoration(
                        labelText: s('report_type') ?? 'Type de rapport',
                        prefixIcon: Icon(
                          Icons.label_outline_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...kReportTypes.map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(s(t) ?? t),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => tempType = v),
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
                        labelText: s('date') ?? 'Date',
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
                                tempType = null;
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
                                _filterType = tempType;
                                _filterDate = tempDate;
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

  void _showAddReportSheet(BuildContext context, String lang) {
    if (_chantiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('create_chantier_first', lang)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReportSheet(
        lang: lang,
        chantiers: _chantiers,
        onCreated: _loadData,
      ),
    );
  }

  void _showReportDetail(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);

    final typeColor = _typeColor(item['type'] as String);
    final typeIcon = _typeIcon(item['type'] as String);
    final typeLabel = s(item['type'] as String);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['chantierNom'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['date'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(
                  item['content'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${s('author')} : ${item['author'] as String}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    s('close'),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    String s(String k) => AppStrings.get(k, lang);
    final filtered = _filteredReports;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppBarWidget(
            title: s('reports'),
            showAvatar: false,
            subtitle: AppStrings.getP('reports_total', lang, {
              'n': '${_rapports.length}',
            }),
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
                          Icons.description_outlined,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            s('no_reports'),
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
                        final item = filtered[index];
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
                          child: _ReportCard(
                            chantierNom: item['chantierNom'] as String,
                            author: item['author'] as String,
                            date: item['date'] as String,
                            content: item['content'] as String,
                            typeColor: _typeColor(item['type'] as String),
                            typeIcon: _typeIcon(item['type'] as String),
                            typeLabel: s(item['type'] as String),
                            onTap: () => _showReportDetail(context, item),
                            onDelete:
                                _isAdmin // ← AJOUTÉ
                                ? () async {
                                    try {
                                      final rapport =
                                          item['rapport'] as Rapport;
                                      await RapportService().delete(rapport.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Rapport supprimé'),
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
        onPressed: () => _showAddReportSheet(context, lang),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          s('add_report'),
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
          label: '${s('chantier') ?? 'Chantier'}: $chantierNom',
          onRemove: () {
            setState(() => _filterChantierId = null);
            _listAnimController.reset();
            _listAnimController.forward();
          },
        ),
      );
    }
    if (_filterType != null) {
      chips.add(
        _FilterChip(
          label:
              '${s('report_type') ?? 'Type'}: ${s(_filterType!) ?? _filterType}',
          onRemove: () {
            setState(() => _filterType = null);
            _listAnimController.reset();
            _listAnimController.forward();
          },
        ),
      );
    }
    if (_filterDate != null) {
      chips.add(
        _FilterChip(
          label: '${s('date') ?? 'Date'}: ${_formatDate(_filterDate!)}',
          onRemove: () {
            setState(() => _filterDate = null);
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

class _ReportCard extends StatelessWidget {
  final String chantierNom;
  final String author;
  final String date;
  final String content;
  final Color typeColor;
  final IconData typeIcon;
  final String typeLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDelete; // ← AJOUTÉ

  const _ReportCard({
    required this.chantierNom,
    required this.author,
    required this.date,
    required this.content,
    required this.typeColor,
    required this.typeIcon,
    required this.typeLabel,
    this.onTap,
    this.onDelete, // ← AJOUTÉ
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: typeColor, width: 3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
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
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          chantierNom,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      date,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                  // ← AJOUTÉ : bouton suppression admin
                  if (onDelete != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: AdminDeleteButton(onDelete: onDelete!),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
}

class _AddReportSheet extends StatefulWidget {
  final String lang;
  final List<Chantier> chantiers;
  final VoidCallback? onCreated;

  const _AddReportSheet({
    required this.lang,
    required this.chantiers,
    this.onCreated,
  });

  @override
  State<_AddReportSheet> createState() => _AddReportSheetState();
}

class _AddReportSheetState extends State<_AddReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  String _selectedType = 'daily';
  int? _selectedChantierId;
  DateTime _dateRapport = DateTime.now();
  bool _isSaving = false;

  final List<XFile> _pickedImages = [];
  final _picker = ImagePicker();

  final List<String> _types = [
    'daily',
    'monthly',
    'inspection',
    'incident',
    'meeting',
    'closure',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceChooser() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedImages.add(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChantierId == null) return;

    setState(() => _isSaving = true);
    try {
      final prefix = '[$_selectedType] ';
      final rapport = await RapportService().create(
        contenu: prefix + _contentController.text.trim(),
        dateRapport: _dateRapport,
        chantierId: _selectedChantierId!,
        auteurId: AuthSession().user!.id,
      );

      for (final img in _pickedImages) {
        await PhotoService().upload(filePath: img.path, rapportId: rapport.id);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('report_created', widget.lang)),
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
    String s(String k) => AppStrings.get(k, widget.lang);

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
                s('new_report'),
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
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: s('report_type'),
                  prefixIcon: Icon(
                    Icons.label_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(s(t))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '${s('content')} *',
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s('error_required') : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text:
                      '${_dateRapport.year}-${_dateRapport.month.toString().padLeft(2, '0')}-${_dateRapport.day.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateRapport,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _dateRapport = picked);
                },
                decoration: InputDecoration(
                  labelText: s('date'),
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
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _showImageSourceChooser,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(s('attach_photos')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_pickedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_pickedImages[i].path),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _pickedImages.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
