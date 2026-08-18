import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/api/data_services.dart';
import '../../core/api/admin_services.dart' show AlerteService;
import '../../core/api/auth_session.dart';
import '../../core/models/depense.dart';
import '../../core/models/photo.dart';
import '../../core/models/rapport.dart';
import '../../core/models/tache.dart';
import '../../core/utils/chantier_mapper.dart'
    show formatDate, formatMoneyCompactWithSymbol, formatMoneyWithSymbol;
import '../reports_screen/reports_screen.dart' show parseReportContent;
import '../../widgets/full_text_dialog.dart';
import '../../theme/app_theme.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';

class ChantierDetailScreen extends StatefulWidget {
  final Map<String, dynamic> chantier;
  const ChantierDetailScreen({super.key, required this.chantier});

  @override
  State<ChantierDetailScreen> createState() => _ChantierDetailScreenState();
}

class _ChantierDetailScreenState extends State<ChantierDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _chantier;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _chantier = Map<String, dynamic>.from(widget.chantier);
    _loadChantier();
  }

  Future<void> _loadChantier() async {
    final id = _chantier['id'];
    if (id == null) return;
    setState(() => _isLoading = true);
    try {
      final c = await ChantierService().getById(
        id is int ? id : int.parse('$id'),
      );
      if (!mounted) return;
      setState(() {
        _chantier = {
          'id': c.id,
          'name': c.nom,
          'address': c.localisation,
          'status': c.statut,
          'dateDebut': c.dateDebut != null ? formatDate(c.dateDebut!) : null,
          'dateFin': c.dateFinPrevue != null
              ? formatDate(c.dateFinPrevue!)
              : null,
          'dateDebutReelle': c.dateDebutReelle != null
              ? formatDate(c.dateDebutReelle!)
              : null,
          'dateFinReelle': c.dateFinReelle != null
              ? formatDate(c.dateFinReelle!)
              : null,
          'budget': c.budget,
          'symbol': c.symbol ?? '€',
          'devise': c.devise ?? 'EUR',
          'progress': (c.avancement ?? 0) / 100.0,
          'avancement': c.avancement ?? 0,
          'description': c.description,
          'client': c.client,
          'chefChantier': c.chefNom,
          'chefId': c.chefId,
          'suspendu': c.suspendu ?? false,
          'canDemarrer': c.canDemarrer ?? false,
          'canTerminer': c.canTerminer ?? false,
          'isEnRetard': c.isEnRetard ?? false,
          'joursRetard': c.joursRetard ?? 0,
          'isAttention': c.isAttention ?? false,
          'nbTachesTotal': c.nbTachesTotal ?? 0,
          'nbTachesTerminees': c.nbTachesTerminees ?? 0,
          'nbTachesEnCours': c.nbTachesEnCours ?? 0,
          'nbTachesPlanifiees': c.nbTachesPlanifiees ?? 0,
          'nbTachesRetard': c.nbTachesRetard ?? 0,
          'latitude': c.latitude,
          'longitude': c.longitude,
          'adresseComplete': c.adresseComplete,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _demarrer() async {
    final id = _chantier['id'];
    if (id == null) return;
    setState(() => _isLoading = true);
    try {
      await ChantierService().demarrer(id is int ? id : int.parse('$id'));
      await _loadChantier();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('start_task', _lang)),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _terminer() async {
    final id = _chantier['id'];
    if (id == null) return;
    setState(() => _isLoading = true);
    try {
      await ChantierService().terminer(id is int ? id : int.parse('$id'));
      await _loadChantier();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('complete_task', _lang)),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _suspendre() async {
    final id = _chantier['id'];
    if (id == null) return;
    setState(() => _isLoading = true);
    try {
      await ChantierService().suspendre(id is int ? id : int.parse('$id'));
      await _loadChantier();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reprendre() async {
    final id = _chantier['id'];
    if (id == null) return;
    setState(() => _isLoading = true);
    try {
      await ChantierService().reprendre(id is int ? id : int.parse('$id'));
      await _loadChantier();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(dynamic e) {
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

  String get _lang => AppState().locale.languageCode;

  Color _statusColor(String status) {
    switch (status) {
      case 'en_cours':
        return AppTheme.statusEnCours;
      case 'planifie':
        return AppTheme.statusPlanifie;
      case 'retard':
        return AppTheme.statusRetard;
      case 'termine':
        return AppTheme.statusTermine;
      case 'attention':
        return const Color(0xFFFF9800);
      case 'en_attente':
        return AppTheme.statusEnAttente;
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
      case 'termine':
        return Icons.check_circle_outline_rounded;
      case 'attention':
        return Icons.notification_important_rounded;
      case 'en_attente':
        return Icons.hourglass_empty_rounded;
      case 'suspendu':
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.business_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = _lang;
    String s(String k) => AppStrings.get(k, lang);
    final chantier = _chantier;
    final statusColor = _statusColor(chantier['status'] ?? 'planifie');
    final statusLabel = s(chantier['status'] ?? 'planifie');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: statusColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 56,
                right: 16,
                bottom: 8,
              ),
              title: Text(
                chantier['name'] ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                color: statusColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                chantier['address'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white38,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: statusColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(text: s('info')),
                    Tab(text: s('budget')),
                    Tab(text: s('tasks')),
                    Tab(text: s('reports')),
                    const Tab(text: 'Galerie'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _isLoading && chantier['status'] == null
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _InfoTab(
                    chantier: chantier,
                    s: s,
                    theme: theme,
                    isLoading: _isLoading,
                    onDemarrer: chantier['canDemarrer'] == true
                        ? _demarrer
                        : null,
                    onTerminer: chantier['canTerminer'] == true
                        ? _terminer
                        : null,
                    onSuspendre:
                        (chantier['suspendu'] != true &&
                            chantier['status'] != 'termine')
                        ? _suspendre
                        : null,
                    onReprendre: chantier['suspendu'] == true
                        ? _reprendre
                        : null,
                  ),
                  _BudgetTab(chantier: widget.chantier, s: s, theme: theme),
                  _TasksTab(chantier: widget.chantier, s: s, theme: theme),
                  _ReportsTab(chantier: widget.chantier, s: s, theme: theme),
                  _GalerieTab(chantier: widget.chantier, theme: theme),
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// INFO TAB — AVEC CARTE OPENSTREETMAP ET BOUTONS GOOGLE MAPS V2
// ============================================================================

class _InfoTab extends StatelessWidget {
  final Map<String, dynamic> chantier;
  final String Function(String) s;
  final ThemeData theme;
  final bool isLoading;
  final VoidCallback? onDemarrer;
  final VoidCallback? onTerminer;
  final VoidCallback? onSuspendre;
  final VoidCallback? onReprendre;

  const _InfoTab({
    required this.chantier,
    required this.s,
    required this.theme,
    this.isLoading = false,
    this.onDemarrer,
    this.onTerminer,
    this.onSuspendre,
    this.onReprendre,
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

  bool get _hasCoords {
    final lat = chantier['latitude'];
    final lng = chantier['longitude'];
    return lat != null && lng != null;
  }

  LatLng? get _coords {
    if (!_hasCoords) return null;
    return LatLng(
      (chantier['latitude'] as num).toDouble(),
      (chantier['longitude'] as num).toDouble(),
    );
  }

  Future<void> _openGoogleMaps() async {
    final coords = _coords;
    if (coords == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openItineraire() async {
    final coords = _coords;
    if (coords == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${coords.latitude},${coords.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAddress() async {
    final address = chantier['adresseComplete'] ?? chantier['address'];
    if (address == null || (address as String).isEmpty) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (chantier['progress'] as double? ?? 0.0);
    final statusColor = _statusColor(chantier['status'] ?? 'planifie');
    final displayAddress =
        (chantier['adresseComplete'] ?? chantier['address'] ?? '—') as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (onDemarrer != null ||
              onTerminer != null ||
              onSuspendre != null ||
              onReprendre != null)
            _Card(
              theme: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s('actions'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (onDemarrer != null)
                        _ActionChip(
                          icon: Icons.play_arrow_rounded,
                          label: s('start_task'),
                          color: AppTheme.statusEnCours,
                          onTap: onDemarrer,
                        ),
                      if (onTerminer != null)
                        _ActionChip(
                          icon: Icons.check_rounded,
                          label: s('complete_task'),
                          color: AppTheme.statusTermine,
                          onTap: onTerminer,
                        ),
                      if (onSuspendre != null)
                        _ActionChip(
                          icon: Icons.pause_rounded,
                          label: s('suspend_task'),
                          color: Colors.grey,
                          onTap: onSuspendre,
                        ),
                      if (onReprendre != null)
                        _ActionChip(
                          icon: Icons.play_arrow_rounded,
                          label: s('resume_task'),
                          color: AppTheme.statusEnCours,
                          onTap: onReprendre,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (onDemarrer != null ||
              onTerminer != null ||
              onSuspendre != null ||
              onReprendre != null)
            const SizedBox(height: 16),

          // Avancement
          _Card(
            theme: theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s('progress'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      '${chantier['nbTachesTerminees'] ?? 0}/${chantier['nbTachesTotal'] ?? 0} tâches',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? AppTheme.statusTermine : statusColor,
                    ),
                  ),
                ),
                if (chantier['isEnRetard'] == true &&
                    (chantier['joursRetard'] ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statusRetard.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.statusRetard.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.statusRetard,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${s('delay_days')} : ${chantier['joursRetard']} ${(chantier['joursRetard'] ?? 0) > 1 ? 'jours' : 'jour'}',
                            style: TextStyle(
                              color: AppTheme.statusRetard,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (chantier['isAttention'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF9800).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notification_important_rounded,
                            color: Color(0xFFFF9800),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s('attention'),
                            style: const TextStyle(
                              color: Color(0xFFFF9800),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_hasCoords)
            _Card(
              theme: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Localisation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _coords!,
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.pinchZoom |
                                InteractiveFlag.drag,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.chantierpro',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _coords!,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent,
                                  size: 44,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _openAddress,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayAddress,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.open_in_new_rounded,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openGoogleMaps,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Voir sur Google Maps'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _openItineraire,
                          icon: const Icon(Icons.directions_rounded, size: 18),
                          label: const Text('Itinéraire'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_hasCoords) const SizedBox(height: 16),

          // Dates
          _Card(
            theme: theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s('date'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateBox(
                        label: s('start_date'),
                        value: chantier['dateDebut'],
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateBox(
                        label: s('end_date'),
                        value: chantier['dateFin'],
                        icon: Icons.event_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateBox(
                        label: s('actual_start'),
                        value: chantier['dateDebutReelle'],
                        icon: Icons.play_arrow_outlined,
                        isReal: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateBox(
                        label: s('actual_end'),
                        value: chantier['dateFinReelle'],
                        icon: Icons.check_outlined,
                        isReal: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Informations
          _Card(
            theme: theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s('info'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.construction_rounded,
                  label: s('chantier_name'),
                  value: chantier['name'] ?? '—',
                  theme: theme,
                ),
                _DetailRow(
                  icon: Icons.description_outlined,
                  label: s('description'),
                  value: chantier['description'] ?? '—',
                  theme: theme,
                ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: s('address'),
                  value: chantier['address'] ?? '—',
                  theme: theme,
                ),
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Chef de chantier',
                  value: chantier['chefChantier'] ?? '—',
                  theme: theme,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Tâches
          _Card(
            theme: theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s('tasks_stats'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: s('tasks_total').replaceAll('{n}', ''),
                        value: '${chantier['nbTachesTotal'] ?? 0}',
                        color: theme.colorScheme.onSurfaceVariant,
                        icon: Icons.folder_outlined,
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: _StatBox(
                        label: s('tasks_completed'),
                        value: '${chantier['nbTachesTerminees'] ?? 0}',
                        color: AppTheme.statusTermine,
                        icon: Icons.check_circle_outline,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: s('tasks_in_progress'),
                        value: '${chantier['nbTachesEnCours'] ?? 0}',
                        color: AppTheme.statusEnCours,
                        icon: Icons.play_circle_outline,
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: _StatBox(
                        label: s('tasks_planned'),
                        value: '${chantier['nbTachesPlanifiees'] ?? 0}',
                        color: AppTheme.statusPlanifie,
                        icon: Icons.schedule_outlined,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                if ((chantier['nbTachesRetard'] ?? 0) > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: s('tasks_delayed'),
                          value: '${chantier['nbTachesRetard']}',
                          color: AppTheme.statusRetard,
                          icon: Icons.warning_amber_outlined,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final ThemeData theme;
  final Widget child;
  const _Card({required this.theme, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final bool isLast;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              showFullTextDialog(context, title: label, content: value),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final bool isReal;
  const _DateBox({
    required this.label,
    required this.value,
    required this.icon,
    this.isReal = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null && value != '—' && value!.isNotEmpty;
    final display = value ?? '—';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasValue
            ? (isReal
                  ? AppTheme.success.withOpacity(0.08)
                  : AppTheme.primary.withOpacity(0.08))
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue
              ? (isReal
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.primary.withOpacity(0.3))
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: hasValue
                    ? (isReal ? AppTheme.success : AppTheme.primary)
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            display,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: hasValue
                  ? (isReal ? AppTheme.success : AppTheme.primary)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final ThemeData theme;
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BUDGET TAB
// ============================================================================

class _BudgetTab extends StatefulWidget {
  final Map<String, dynamic> chantier;
  final String Function(String) s;
  final ThemeData theme;
  const _BudgetTab({
    required this.chantier,
    required this.s,
    required this.theme,
  });
  @override
  State<_BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<_BudgetTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _error;
  List<Depense> _depenses = [];
  @override
  bool get wantKeepAlive => true;
  int? get _chantierId {
    final id = widget.chantier['id'];
    return id is int ? id : int.tryParse('$id');
  }

  double get _budget => ((widget.chantier['budget'] as num?) ?? 0).toDouble();
  String get _symbol => widget.chantier['symbol'] as String? ?? '€';
  double get _consumed =>
      _depenses.fold<double>(0, (sum, d) => sum + (d.montant ?? 0));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final all = await DepenseService().getAll();
      if (!mounted) return;
      setState(() {
        _depenses = all.where((d) => d.chantierId == _chantierId).toList()
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

  Future<void> _checkBudgetThresholds(double before, double after) async {
    final id = _chantierId;
    if (id == null || _budget <= 0) return;
    final ratioBefore = before / _budget;
    final ratioAfter = after / _budget;
    final nom = widget.chantier['name'] ?? '';
    try {
      if (ratioBefore < 1.0 && ratioAfter >= 1.0) {
        await AlerteService().create(
          message:
              'Budget dépassé sur "$nom" : ${formatMoneyWithSymbol(after, _symbol)} / ${formatMoneyWithSymbol(_budget, _symbol)}',
          statut: 'non_lue',
          chantierId: id,
        );
      } else if (ratioBefore < 0.8 && ratioAfter >= 0.8) {
        await AlerteService().create(
          message:
              'Budget à ${(ratioAfter * 100).toInt()}% sur "$nom" — vigilance recommandée',
          statut: 'non_lue',
          chantierId: id,
        );
      }
    } catch (_) {}
  }

  void _showAddDepenseSheet() {
    final id = _chantierId;
    if (id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDepenseSheet(
        chantierId: id,
        symbol: _symbol,
        onCreated: (montant) async {
          final before = _consumed;
          await _load();
          await _checkBudgetThresholds(before, before + montant);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = widget.theme;
    final s = widget.s;
    final budget = _budget;
    final consumed = _consumed;
    final remaining = budget - consumed;
    final ratio = budget > 0 ? consumed / budget : 0.0;

    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    if (_error != null)
      return _TabMessage(
        theme: theme,
        icon: Icons.cloud_off_rounded,
        message: _error!,
        onRetry: _load,
        retryLabel: s('retry'),
      );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          child: Column(
            children: [
              _Card(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s('budget'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _BudgetStat(
                            label: s('budget'),
                            value: formatMoneyCompactWithSymbol(
                              budget,
                              _symbol,
                            ),
                            color: AppTheme.primary,
                            icon: Icons.account_balance_wallet_outlined,
                            theme: theme,
                          ),
                        ),
                        Expanded(
                          child: _BudgetStat(
                            label: s('consumed'),
                            value: formatMoneyCompactWithSymbol(
                              consumed,
                              _symbol,
                            ),
                            color: AppTheme.statusEnAttente,
                            icon: Icons.trending_up_rounded,
                            theme: theme,
                          ),
                        ),
                        Expanded(
                          child: _BudgetStat(
                            label: s('remaining'),
                            value: formatMoneyCompactWithSymbol(
                              remaining,
                              _symbol,
                            ),
                            color: remaining >= 0
                                ? AppTheme.statusTermine
                                : AppTheme.statusRetard,
                            icon: Icons.savings_outlined,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${(ratio * 100).toInt()}% ${s('consumed').toLowerCase()}${ratio >= 1.0 ? ' — ${s('budget_exceeded')}' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: ratio >= 1.0
                            ? AppTheme.statusRetard
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: ratio >= 1.0
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ratio >= 1.0
                              ? AppTheme.statusRetard
                              : ratio >= 0.8
                              ? AppTheme.statusEnAttente
                              : AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s('expenses'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_depenses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            s('no_expenses'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._depenses.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.payments_rounded,
                                  color: AppTheme.success,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.description?.isNotEmpty == true
                                          ? d.description!
                                          : s('expenses'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      d.dateDepense != null
                                          ? formatDate(d.dateDepense!)
                                          : '—',
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
                              Text(
                                formatMoneyWithSymbol(d.montant ?? 0, _symbol),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_depense_fab',
        onPressed: _showAddDepenseSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          s('add_expense'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _AddDepenseSheet extends StatefulWidget {
  final int chantierId;
  final String symbol;
  final Future<void> Function(double montant) onCreated;
  const _AddDepenseSheet({
    required this.chantierId,
    required this.symbol,
    required this.onCreated,
  });
  @override
  State<_AddDepenseSheet> createState() => _AddDepenseSheetState();
}

class _AddDepenseSheetState extends State<_AddDepenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  String _s(String k) => AppStrings.get(k, AppState().locale.languageCode);

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = formatDate(_date);
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final montant = double.parse(_montantCtrl.text.replaceAll(',', '.'));
    try {
      await DepenseService().create(
        montant: montant,
        description: _descCtrl.text.trim(),
        dateDepense: _date,
        chantierId: widget.chantierId,
      );
      if (mounted) {
        Navigator.pop(context);
        await widget.onCreated(montant);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.errorMessage(e)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                _s('add_expense'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _montantCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '${_s('amount')} (${widget.symbol}) *',
                  prefixIcon: Icon(
                    Icons.payments_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return _s('error_required');
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return _s('invalid_amount');
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: _s('description'),
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                readOnly: true,
                controller: _dateCtrl,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                    _dateCtrl.text = formatDate(_date);
                  }
                },
                decoration: InputDecoration(
                  labelText: _s('expense_date'),
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
                        _s('save'),
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

// ============================================================================
// TASKS TAB
// ============================================================================

class _TasksTab extends StatefulWidget {
  final Map<String, dynamic> chantier;
  final String Function(String) s;
  final ThemeData theme;
  const _TasksTab({
    required this.chantier,
    required this.s,
    required this.theme,
  });
  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _error;
  List<Tache> _taches = [];
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final id = widget.chantier['id'];
      final taches = await TacheService().getAll(
        chantierId: id is int ? id : int.tryParse('$id'),
      );
      if (!mounted) return;
      setState(() {
        _taches = taches;
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

  Color _statusColor(String status) {
    switch (status) {
      case 'en_cours':
        return AppTheme.statusEnCours;
      case 'planifie':
        return AppTheme.statusPlanifie;
      case 'retard':
        return AppTheme.statusRetard;
      case 'termine':
        return AppTheme.statusTermine;
      case 'en_attente':
        return AppTheme.statusEnAttente;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = widget.theme;
    final s = widget.s;
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    if (_error != null)
      return _TabMessage(
        theme: theme,
        icon: Icons.cloud_off_rounded,
        message: _error!,
        onRetry: _load,
        retryLabel: s('retry'),
      );
    if (_taches.isEmpty)
      return _TabMessage(
        theme: theme,
        icon: Icons.task_outlined,
        message: s('no_tasks'),
      );

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _taches.length,
        itemBuilder: (context, index) {
          final task = _taches[index];
          final color = _statusColor(task.statut);
          return GestureDetector(
            onTap: () => showFullTextDialog(
              context,
              title: task.titre,
              subtitle:
                  '${task.dateDebut != null ? formatDate(task.dateDebut!) : '—'} → ${task.dateFin != null ? formatDate(task.dateFin!) : '—'}',
              content: (task.description ?? '').isNotEmpty
                  ? task.description!
                  : task.titre,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.titre,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    task.dateFin != null ? formatDate(task.dateFin!) : '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s(task.statut),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
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
}

// ============================================================================
// REPORTS TAB
// ============================================================================

class _ReportsTab extends StatefulWidget {
  final Map<String, dynamic> chantier;
  final String Function(String) s;
  final ThemeData theme;
  const _ReportsTab({
    required this.chantier,
    required this.s,
    required this.theme,
  });
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _error;
  List<Rapport> _rapports = [];
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final id = widget.chantier['id'];
      final rapports = await RapportService().getAll(
        chantierId: id is int ? id : int.tryParse('$id'),
      );
      if (!mounted) return;
      setState(() {
        _rapports = rapports..sort((a, b) => b.id.compareTo(a.id));
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = widget.theme;
    final s = widget.s;
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    if (_error != null)
      return _TabMessage(
        theme: theme,
        icon: Icons.cloud_off_rounded,
        message: _error!,
        onRetry: _load,
        retryLabel: s('retry'),
      );
    if (_rapports.isEmpty)
      return _TabMessage(
        theme: theme,
        icon: Icons.description_outlined,
        message: s('no_reports'),
      );

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _rapports.length,
        itemBuilder: (context, index) {
          final rapport = _rapports[index];
          final parsed = parseReportContent(rapport.contenu);
          return GestureDetector(
            onTap: () => showFullTextDialog(
              context,
              title: s(parsed.type),
              subtitle: rapport.dateRapport != null
                  ? formatDate(rapport.dateRapport!)
                  : null,
              content: parsed.content,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s(parsed.type),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        rapport.dateRapport != null
                            ? formatDate(rapport.dateRapport!)
                            : '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    parsed.content,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// GALERIE TAB
// ============================================================================

class _GalerieTab extends StatefulWidget {
  final Map<String, dynamic> chantier;
  final ThemeData theme;
  const _GalerieTab({required this.chantier, required this.theme});
  @override
  State<_GalerieTab> createState() => _GalerieTabState();
}

class _GalerieTabState extends State<_GalerieTab>
    with AutomaticKeepAliveClientMixin {
  final _picker = ImagePicker();
  bool _isLoading = true;
  bool _isUploading = false;
  String? _error;
  List<Photo> _photos = [];
  List<Rapport> _rapports = [];
  @override
  bool get wantKeepAlive => true;
  int? get _chantierId {
    final id = widget.chantier['id'];
    return id is int ? id : int.tryParse('$id');
  }

  /// Seul un admin peut supprimer des photos de la galerie.
  bool get _isAdmin => AuthSession().user?.role == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rapports = await RapportService().getAll(chantierId: _chantierId);
      final photosLists = await Future.wait(
        rapports.map((r) => PhotoService().getAll(rapportId: r.id)),
      );
      if (!mounted) return;
      final photos = photosLists.expand((l) => l).toList()
        ..sort((a, b) => b.id.compareTo(a.id));
      setState(() {
        _rapports = rapports..sort((a, b) => b.id.compareTo(a.id));
        _photos = photos;
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

  String _s(String k) => AppStrings.get(k, AppState().locale.languageCode);

  Future<void> _addPhoto(ImageSource source) async {
    if (_rapports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s('create_first_report')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      return;
    }
    if (file == null) return;
    setState(() => _isUploading = true);
    try {
      await PhotoService().upload(
        filePath: file.path,
        rapportId: _rapports.first.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_s('photo_uploaded')),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.errorMessage(e)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAddPhotoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(_s('pick_from_gallery')),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(_s('take_photo')),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmation + appel API + retrait local de la photo.
  Future<void> _deletePhoto(Photo photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text(
          'Cette action est irréversible. Voulez-vous vraiment supprimer cette photo ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Supprimer',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await PhotoService().delete(photo.id);
      if (mounted) {
        setState(() => _photos.removeWhere((p) => p.id == photo.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo supprimée'),
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
    }
  }

  void _showPhotoDetail(Photo photo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Image.network(
                    photo.fullUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: widget.theme.colorScheme.surface,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded),
                      ),
                    ),
                  ),
                  if (_isAdmin)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                          tooltip: 'Supprimer',
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deletePhoto(photo);
                          },
                        ),
                      ),
                    ),
                ],
              ),
              Container(
                width: double.infinity,
                color: widget.theme.colorScheme.surface,
                padding: const EdgeInsets.all(16),
                child: Text(
                  photo.dateUpload != null
                      ? formatDate(photo.dateUpload!)
                      : '—',
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: widget.theme.colorScheme.onSurfaceVariant,
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
  Widget build(BuildContext context) {
    super.build(context);
    final theme = widget.theme;
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    if (_error != null)
      return _TabMessage(
        theme: theme,
        icon: Icons.cloud_off_rounded,
        message: _error!,
        onRetry: _load,
        retryLabel: _s('retry'),
      );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _photos.isEmpty
          ? _TabMessage(
              theme: theme,
              icon: Icons.photo_library_outlined,
              message: _s('no_photos'),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return GestureDetector(
                    onTap: () => _showPhotoDetail(photo),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            photo.fullUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (_isAdmin)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _deletePhoto(photo),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_photo_fab',
        onPressed: _isUploading ? null : _showAddPhotoSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: _isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_a_photo_outlined),
        label: Text(
          _s('add_photo'),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================

class _TabMessage extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  const _TabMessage({
    required this.theme,
    required this.icon,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final ThemeData theme;
  const _BudgetStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
