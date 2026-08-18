import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/auth_session.dart';
import '../../core/api/data_services.dart';
import '../../core/api/admin_services.dart';
import '../../core/api/refresh_bus.dart';
import '../../core/models/alerte.dart';
import '../../core/models/chantier.dart';
import '../../core/models/depense.dart';
import '../../core/models/rapport.dart';
import '../../core/models/tache.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';
import '../../core/utils/pending_filters.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/loading_skeleton_widget.dart';
import './widgets/alert_banner_widget.dart';
import './widgets/dashboard_chart_widget.dart';
import './widgets/kpi_card_widget.dart';
import './widgets/notifications_sheet.dart';
import './widgets/recent_chantiers_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;

  List<Chantier> _chantiers = [];
  List<Tache> _taches = [];
  List<Rapport> _rapports = [];
  List<Depense> _depenses = [];
  List<Alerte> _alertes = [];

  late AnimationController _staggerController;
  final List<Animation<double>> _cardAnims = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    for (int i = 0; i < 6; i++) {
      final start = (i * 0.12).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      _cardAnims.add(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    }

    RefreshBus().addListener(_loadData);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ChantierService().getAll(),
        TacheService().getAll(),
        RapportService().getAll(),
        DepenseService().getAll(),
        AlerteService().getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _chantiers = results[0] as List<Chantier>;
        _taches = results[1] as List<Tache>;
        _rapports = results[2] as List<Rapport>;
        _depenses = results[3] as List<Depense>;
        _alertes = (results[4] as List<Alerte>)
          ..sort((a, b) => b.id.compareTo(a.id));
        _isLoading = false;
      });
      _staggerController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = ApiClient.errorMessage(e);
      });
    }
  }

  Future<void> _onRefresh() => _loadData();

  @override
  void dispose() {
    RefreshBus().removeListener(_loadData);
    _staggerController.dispose();
    super.dispose();
  }

  // ─── Conversion locale : Chantier → Map (remplace chantierToUiMap) ───────

  Map<String, dynamic> _chantierToMap(Chantier c) {
    return {
      'id': c.id,
      'name': c.nom,
      'address': c.localisation,
      'status': c.statut,
      'dateDebut': c.dateDebut != null ? _formatDate(c.dateDebut!) : null,
      'dateFin': c.dateFinPrevue != null ? _formatDate(c.dateFinPrevue!) : null,
      'dateDebutReelle': c.dateDebutReelle != null
          ? _formatDate(c.dateDebutReelle!)
          : null,
      'dateFinReelle': c.dateFinReelle != null
          ? _formatDate(c.dateFinReelle!)
          : null,
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
      'tachesTerminees': c.nbTachesTerminees,
      'nbTaches': c.nbTachesTotal,
    };
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatTotalsByDevise(Map<String, double> totals) {
    if (totals.isEmpty) return '0';
    if (totals.length == 1) {
      final e = totals.entries.first;
      return '${e.value.toStringAsFixed(0)} ${e.key}';
    }
    return totals.entries
        .map((e) => '${e.value.toStringAsFixed(0)} ${e.key}')
        .join(' / ');
  }

  // ─── Indicateurs calculés depuis les données réelles ─────────────────────

  int get _chantiersActifs =>
      _chantiers.where((c) => c.statut == 'en_cours').length;

  int get _chantiersEnRetard =>
      _chantiers.where((c) => c.statut == 'retard').length;

  int get _tachesEnRetard => _taches.where((t) => t.isEnRetard).length;

  /// Totaux groupés par devise (chaque chantier garde la sienne).
  Map<String, double> get _budgetParDevise {
    final m = <String, double>{};
    for (final c in _chantiers) {
      final devise = c.devise ?? 'EUR'; // ← CORRECTION : fallback si null
      m[devise] = (m[devise] ?? 0) + c.budget;
    }
    return m;
  }

  Map<String, double> get _consommeParDevise {
    final deviseParChantier = {for (final c in _chantiers) c.id: c.devise};
    final m = <String, double>{};
    for (final d in _depenses) {
      final dev = deviseParChantier[d.chantierId] ?? 'EUR';
      m[dev] = (m[dev] ?? 0) + d.montant;
    }
    return m;
  }

  int get _notificationCount =>
      _chantiersEnRetard + _tachesEnRetard + _alertes.length;

  void _openChantier(Chantier c) {
    final ui = _chantierToMap(c);
    context.go('/chantiers/detail', extra: ui);
  }

  void _showNotifications() {
    final lang = AppState().locale.languageCode;
    showNotificationsSheet(
      context,
      notifications: buildNotifications(
        chantiers: _chantiers,
        taches: _taches,
        alertes: _alertes,
        lang: lang,
      ),
      onOpenChantier: _openChantier,
    );
  }

  int get _rapportsCeMois {
    final now = DateTime.now();
    return _rapports
        .where(
          (r) =>
              r.dateRapport != null &&
              r.dateRapport!.year == now.year &&
              r.dateRapport!.month == now.month,
        )
        .length;
  }

  List<ChartEntry> get _chartEntries {
    final entries = <ChartEntry>[];
    for (final c in _chantiers.take(6)) {
      final pct = c.avancement.toDouble();
      final Color color;
      if (c.statut == 'retard') {
        color = AppTheme.statusRetard;
      } else if (pct >= 75) {
        color = AppTheme.success;
      } else if (pct < 45) {
        color = AppTheme.statusEnAttente;
      } else {
        color = AppTheme.primary;
      }
      final shortName = c.nom.length > 9 ? '${c.nom.substring(0, 8)}…' : c.nom;
      entries.add(ChartEntry(shortName, pct, color));
    }
    return entries;
  }

  List<Map<String, dynamic>> get _recentItems {
    final sorted = List<Chantier>.from(_chantiers)
      ..sort((a, b) => b.id.compareTo(a.id));
    return sorted.take(3).map((c) {
      final ui = _chantierToMap(c);
      return {
        ...ui,
        'budgetLabel': '${c.budget.toStringAsFixed(0)} ${c.symbol}',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    final hour = DateTime.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = s('good_morning');
    } else if (hour < 18) {
      greeting = s('good_afternoon');
    } else {
      greeting = s('good_evening');
    }

    final user = AuthSession().user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppBarWidget(
            title: greeting,
            subtitle: user?.nom ?? '',
            showAvatar: false,
            actions: [
              Stack(
                children: [
                  IconButton(
                    onPressed: _showNotifications,
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (_notificationCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: AppTheme.statusRetard,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _notificationCount > 9
                                ? '9+'
                                : '$_notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.primary,
              child: _isLoading
                  ? const DashboardSkeletonWidget()
                  : _error != null
                  ? _buildError(theme)
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_chantiersEnRetard > 0) ...[
                            _buildAlertBanner(),
                            const SizedBox(height: 16),
                          ],
                          _buildKpiGrid(theme),
                          const SizedBox(height: 20),
                          _buildChartSection(theme),
                          const SizedBox(height: 20),
                          _buildRecentSection(theme),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    final lang = AppState().locale.languageCode;
    return ListView(
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
            label: Text(AppStrings.get('retry', lang)),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBanner() {
    final n = _chantiersEnRetard;
    final lang = AppState().locale.languageCode;
    return FadeTransition(
      opacity: _cardAnims.isNotEmpty
          ? _cardAnims[0]
          : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: () {
          final retards = _chantiers
              .where((c) => c.statut == 'retard')
              .toList();
          if (retards.length == 1) {
            _openChantier(retards.first);
          } else {
            PendingFilters().chantierFilter = 'retard';
            context.go('/chantiers');
          }
        },
        child: AlertBannerWidget(
          message: n == 1
              ? AppStrings.get('alert_delay_one', lang)
              : AppStrings.getP('alert_delay_many', lang, {'n': '$n'}),
          count: n,
        ),
      ),
    );
  }

  Widget _buildKpiGrid(ThemeData theme) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    final budgets = _budgetParDevise;
    final consommes = _consommeParDevise;
    final singleDevise = budgets.length <= 1;
    final totalBudget = budgets.values.fold<double>(0, (a, b) => a + b);
    final totalConsomme = consommes.values.fold<double>(0, (a, b) => a + b);
    final consumedPct = (singleDevise && totalBudget > 0)
        ? ((totalConsomme / totalBudget) * 100).toInt()
        : 0;
    final kpiData = [
      _KpiData(
        label: s('active_chantiers'),
        value: '$_chantiersActifs',
        subtitle: '${_chantiers.length} ${s('in_total')}',
        icon: Icons.construction_rounded,
        color: AppTheme.primary,
        animIndex: 1,
        onTap: () {
          PendingFilters().chantierFilter = 'en_cours';
          context.go('/chantiers');
        },
      ),
      _KpiData(
        label: s('late_tasks'),
        value: '$_tachesEnRetard',
        subtitle: AppStrings.getP('of_tasks', lang, {'n': '${_taches.length}'}),
        icon: Icons.warning_amber_rounded,
        color: AppTheme.statusRetard,
        animIndex: 2,
        onTap: () {
          PendingFilters().tacheFilter = 'retard';
          context.go('/tasks');
        },
      ),
      _KpiData(
        label: s('total_budget'),
        value: _formatTotalsByDevise(budgets),
        subtitle: singleDevise
            ? AppStrings.getP('consumed_pct', lang, {'n': '$consumedPct'})
            : s('multi_currency'),
        icon: Icons.payments_rounded,
        color: AppTheme.success,
        animIndex: 3,
        onTap: () {
          PendingFilters().chantierFilter = null;
          context.go('/chantiers');
        },
      ),
      _KpiData(
        label: s('reports_this_month'),
        value: '$_rapportsCeMois',
        subtitle: '${_rapports.length} ${s('in_total')}',
        icon: Icons.description_rounded,
        color: AppTheme.statusPlanifie,
        animIndex: 4,
        onTap: () => context.go('/reports'),
      ),
    ];

    if (isTablet) {
      return Row(
        children: kpiData
            .map(
              (d) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _animatedKpiCard(d),
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _animatedKpiCard(kpiData[0])),
            const SizedBox(width: 12),
            Expanded(child: _animatedKpiCard(kpiData[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _animatedKpiCard(kpiData[2])),
            const SizedBox(width: 12),
            Expanded(child: _animatedKpiCard(kpiData[3])),
          ],
        ),
      ],
    );
  }

  Widget _animatedKpiCard(_KpiData d) {
    final anim = d.animIndex < _cardAnims.length
        ? _cardAnims[d.animIndex]
        : const AlwaysStoppedAnimation<double>(1.0);
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(anim),
        child: GestureDetector(
          onTap: d.onTap,
          child: KpiCardWidget(
            label: d.label,
            value: d.value,
            subtitle: d.subtitle,
            icon: d.icon,
            accentColor: d.color,
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme) {
    final anim = _cardAnims.length > 4
        ? _cardAnims[4]
        : const AlwaysStoppedAnimation<double>(1.0);
    return FadeTransition(
      opacity: anim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get('chart_title', AppState().locale.languageCode),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                AppStrings.get(
                  'chart_subtitle',
                  AppState().locale.languageCode,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_chartEntries.isEmpty)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                AppStrings.get('no_chart_data', AppState().locale.languageCode),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            DashboardChartWidget(entries: _chartEntries),
        ],
      ),
    );
  }

  Widget _buildRecentSection(ThemeData theme) {
    final anim = _cardAnims.length > 5
        ? _cardAnims[5]
        : const AlwaysStoppedAnimation<double>(1.0);
    return FadeTransition(
      opacity: anim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get(
                  'recent_chantiers',
                  AppState().locale.languageCode,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/chantiers'),
                child: Text(
                  AppStrings.get('view_all', AppState().locale.languageCode),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RecentChantiersWidget(
            items: _recentItems,
            onTap: (m) => context.go('/chantiers/detail', extra: m),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int animIndex;
  final VoidCallback? onTap;

  const _KpiData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.animIndex,
    this.onTap,
  });
}
