import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/admin_services.dart';
import '../../core/api/api_client.dart';
import '../../core/api/auth_session.dart';
import '../../core/api/data_services.dart';
import '../../core/api/refresh_bus.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';
import '../../core/models/alerte.dart';
import '../../core/models/chantier.dart';
import '../../core/models/depense.dart';
import '../../core/models/rapport.dart';
import '../../core/models/tache.dart';
import '../../core/models/utilisateur.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';
import '../dashboard_screen/widgets/kpi_card_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;

  List<Utilisateur> _utilisateurs = [];
  List<Chantier> _chantiers = [];
  List<Tache> _taches = [];
  List<Rapport> _rapports = [];
  List<Depense> _depenses = [];
  List<Alerte> _alertes = [];

  @override
  void initState() {
    super.initState();
    RefreshBus().addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    RefreshBus().removeListener(_loadData);
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
        UtilisateurAdminService().getAll(),
        ChantierService().getAll(),
        TacheService().getAll(),
        RapportService().getAll(),
        DepenseService().getAll(),
        AlerteService().getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _utilisateurs = results[0] as List<Utilisateur>;
        _chantiers = results[1] as List<Chantier>;
        _taches = results[2] as List<Tache>;
        _rapports = results[3] as List<Rapport>;
        _depenses = results[4] as List<Depense>;
        _alertes = (results[5] as List<Alerte>)
          ..sort((a, b) => b.id.compareTo(a.id));
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

  int get _nbChefs =>
      _utilisateurs.where((u) => u.role == 'CHEF_CHANTIER').length;
  int get _chantiersActifs =>
      _chantiers.where((c) => c.statut == 'en_cours').length;
  int get _chantiersRetard =>
      _chantiers.where((c) => c.statut == 'retard').length;
  int get _tachesRetard => _taches.where((t) => t.isEnRetard).length;
  int get _alertesNonLues => _alertes.where((a) => a.lu != true).length;

  Map<String, double> get _budgetParDevise {
    final m = <String, double>{};
    for (final c in _chantiers) {
      final devise = c.devise ?? 'EUR';
      m[devise] = (m[devise] ?? 0) + c.budget;
    }
    return m;
  }

  Map<String, double> get _consommeParDevise {
    final deviseParChantier = {
      for (final c in _chantiers) c.id: c.devise ?? 'EUR',
    };
    final m = <String, double>{};
    for (final d in _depenses) {
      final dev = deviseParChantier[d.chantierId] ?? 'EUR';
      m[dev] = (m[dev] ?? 0) + d.montant;
    }
    return m;
  }

  String _chantierNom(int? id) {
    if (id == null) return '—';
    for (final c in _chantiers) {
      if (c.id == id) return c.nom;
    }
    return 'Chantier #$id';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    final user = AuthSession().user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppBarWidget(
            title: s('admin_dashboard'),
            subtitle: user?.nom ?? '',
            showAvatar: false,
            actions: [
              IconButton(
                onPressed: () => context.push(AppRoutes.adminAlertes),
                icon: _alertesNonLues > 0
                    ? Badge(
                        label: Text('$_alertesNonLues'),
                        child: const Icon(Icons.notifications_outlined),
                      )
                    : const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                onPressed: _loadData,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _error != null
                  ? _buildError(theme, s)
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildKpiGrid(s),
                          const SizedBox(height: 24),
                          _buildModulesSection(theme, s),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, String Function(String) s) {
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
            label: Text(s('retry')),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(String Function(String) s) {
    final lang = AppState().locale.languageCode;
    final budgets = _budgetParDevise;
    final consommes = _consommeParDevise;
    final singleDevise = budgets.length <= 1;
    final totalBudget = budgets.values.fold<double>(0, (a, b) => a + b);
    final totalConsomme = consommes.values.fold<double>(0, (a, b) => a + b);
    final consumedPct = (singleDevise && totalBudget > 0)
        ? ((totalConsomme / totalBudget) * 100).toInt()
        : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ClickableKpiCard(
                route: AppRoutes.adminChefs,
                child: KpiCardWidget(
                  label: s('site_managers'),
                  value: '$_nbChefs',
                  subtitle:
                      '${_utilisateurs.length} ${s('users_total_suffix')}',
                  icon: Icons.engineering_rounded,
                  accentColor: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClickableKpiCard(
                route: AppRoutes.adminChantiers,
                child: KpiCardWidget(
                  label: s('active_chantiers'),
                  value: '$_chantiersActifs',
                  subtitle:
                      '${_chantiers.length} ${s('in_total')} · $_chantiersRetard ${s('delayed_suffix')}',
                  icon: Icons.construction_rounded,
                  accentColor: AppTheme.statusEnCours,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ClickableKpiCard(
                route: AppRoutes.adminTasks,
                child: KpiCardWidget(
                  label: s('late_tasks'),
                  value: '$_tachesRetard',
                  subtitle: AppStrings.getP('of_tasks', lang, {
                    'n': '${_taches.length}',
                  }),
                  icon: Icons.warning_amber_rounded,
                  accentColor: AppTheme.statusRetard,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ClickableKpiCard(
                route: AppRoutes.adminDepenses,
                child: KpiCardWidget(
                  label: s('consumed_budget'),
                  value: formatTotalsByDevise(_consommeParDevise),
                  subtitle: singleDevise
                      ? '$consumedPct% ${s('of_budget')} ${formatTotalsByDevise(budgets)}'
                      : s('multi_currency'),
                  icon: Icons.payments_rounded,
                  accentColor: AppTheme.success,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModulesSection(ThemeData theme, String Function(String) s) {
    final modules = [
      _ModuleData(
        title: s('manage_chefs'),
        subtitle: 'CRUD chefs de chantier',
        icon: Icons.engineering_rounded,
        color: AppTheme.primary,
        route: AppRoutes.adminChefs,
      ),
      _ModuleData(
        title: s('assignments'),
        subtitle: 'Affecter les chefs aux chantiers',
        icon: Icons.assignment_ind_rounded,
        color: AppTheme.statusEnCours,
        route: AppRoutes.adminAffectations,
      ),
      _ModuleData(
        title: s('expenses'),
        subtitle: 'Consulter les dépenses',
        icon: Icons.receipt_long_rounded,
        color: AppTheme.success,
        route: AppRoutes.adminDepenses,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s('management_modules'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        ...modules.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => context.push(m.route),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: m.color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(m.icon, color: m.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widget interne pour rendre une tuile KPI cliquable ──
class _ClickableKpiCard extends StatelessWidget {
  final String route;
  final Widget child;

  const _ClickableKpiCard({required this.route, required this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: () => context.push(route), child: child),
    );
  }
}

class _ModuleData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _ModuleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

String formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String formatTotalsByDevise(Map<String, double> totaux) {
  if (totaux.isEmpty) return '';
  final parts = <String>[];
  totaux.forEach((devise, total) {
    final formatted = total.toStringAsFixed(2);
    parts.add('$formatted $devise');
  });
  return parts.join(' · ');
}
