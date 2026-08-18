import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/api/data_services.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';
import '../../core/models/chantier.dart';
import '../../core/models/tache.dart';
import '../../theme/app_theme.dart';

class TacheDetailScreen extends StatefulWidget {
  final int tacheId;

  const TacheDetailScreen({super.key, required this.tacheId});

  @override
  State<TacheDetailScreen> createState() => _TacheDetailScreenState();
}

class _TacheDetailScreenState extends State<TacheDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Tache? _tache;
  List<Map<String, dynamic>> _historique = [];
  List<Chantier> _chantiers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        TacheService().getById(widget.tacheId),
        TacheService().getHistorique(widget.tacheId),
        ChantierService().getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _tache = results[0] as Tache;
        _historique = results[1] as List<Map<String, dynamic>>;
        _chantiers = results[2] as List<Chantier>;
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

  Future<void> _demarrer() async {
    setState(() => _isLoading = true);
    try {
      await TacheService().demarrer(widget.tacheId);
      await _loadData();
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
    setState(() => _isLoading = true);
    try {
      await TacheService().terminer(widget.tacheId);
      await _loadData();
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

  Future<void> _updateAvancement(int value) async {
    setState(() => _isLoading = true);
    try {
      await TacheService().updateAvancement(widget.tacheId, value);
      await _loadData();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _suspendre() async {
    setState(() => _isLoading = true);
    try {
      await TacheService().suspendre(widget.tacheId);
      await _loadData();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reprendre() async {
    setState(() => _isLoading = true);
    try {
      await TacheService().reprendre(widget.tacheId);
      await _loadData();
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
      case 'suspendu':
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _chantierNom(int? id) {
    if (id == null) return '—';
    for (final c in _chantiers) {
      if (c.id == id) return c.nom;
    }
    return 'Chantier #$id';
  }

  void _showAvancementDialog() {
    if (_tache == null) return;
    int tempValue = _tache!.avancement;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(AppStrings.get('progress', _lang)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$tempValue %',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: tempValue.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$tempValue %',
                activeColor: AppTheme.primary,
                onChanged: (v) => setDialogState(() => tempValue = v.round()),
              ),
              Wrap(
                spacing: 8,
                children: [0, 25, 50, 75, 100]
                    .map(
                      (v) => ChoiceChip(
                        label: Text('$v %'),
                        selected: tempValue == v,
                        onSelected: (_) => setDialogState(() => tempValue = v),
                        selectedColor: AppTheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: tempValue == v ? AppTheme.primary : null,
                          fontWeight: tempValue == v ? FontWeight.w600 : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppStrings.get('cancel', _lang)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _updateAvancement(tempValue);
              },
              child: Text(AppStrings.get('save', _lang)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = _lang;

    if (_isLoading && _tache == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(AppStrings.get('tasks', lang))),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_error != null && _tache == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(AppStrings.get('tasks', lang))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppStrings.get('retry', lang)),
              ),
            ],
          ),
        ),
      );
    }

    final t = _tache!;
    final statusColor = _statusColor(t.statut);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: statusColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 56,
                right: 16,
                bottom: 16,
              ),
              title: Text(
                t.titre,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
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
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusIcon(t.statut),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppStrings.get(t.statut, lang),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (t.alerteEcheance)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.notification_important_rounded,
                                    color: Colors.black87,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.get('attention', lang),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionsCard(t, theme, lang),
                  const SizedBox(height: 16),
                  _buildAvancementCard(t, theme, lang),
                  const SizedBox(height: 16),
                  _buildInfoCard(t, theme, lang),
                  const SizedBox(height: 16),
                  _buildDatesCard(t, theme, lang),
                  const SizedBox(height: 16),
                  _buildHistoriqueCard(theme, lang),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(Tache t, ThemeData theme, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('actions', lang),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (t.canDemarrer)
                  _ActionButton(
                    icon: Icons.play_arrow_rounded,
                    label: AppStrings.get('start_task', lang),
                    color: AppTheme.statusEnCours,
                    onTap: _demarrer,
                  ),
                if (t.canUpdateAvancement)
                  _ActionButton(
                    icon: Icons.trending_up_rounded,
                    label: AppStrings.get('progress', lang),
                    color: AppTheme.primary,
                    onTap: _showAvancementDialog,
                  ),
                if (t.canTerminer)
                  _ActionButton(
                    icon: Icons.check_rounded,
                    label: AppStrings.get('complete_task', lang),
                    color: AppTheme.statusTermine,
                    onTap: _terminer,
                  ),
                if (!t.isSuspendue && !t.isTerminee)
                  _ActionButton(
                    icon: Icons.pause_rounded,
                    label: AppStrings.get('suspend_task', lang),
                    color: Colors.grey,
                    onTap: _suspendre,
                  ),
                if (t.isSuspendue)
                  _ActionButton(
                    icon: Icons.play_arrow_rounded,
                    label: AppStrings.get('resume_task', lang),
                    color: AppTheme.statusEnCours,
                    onTap: _reprendre,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvancementCard(Tache t, ThemeData theme, String lang) {
    final progressColor = t.avancement == 100
        ? AppTheme.statusTermine
        : t.isEnRetard
        ? AppTheme.statusRetard
        : t.isAttention
        ? const Color(0xFFFF9800)
        : AppTheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('progress', lang),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: t.avancement / 100,
                      minHeight: 12,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${t.avancement} %',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            if (t.isEnRetard && t.joursRetard > 0)
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
                        '${AppStrings.get('delay_days', lang)} : ${t.joursRetard} ${t.joursRetard > 1 ? 'jours' : 'jour'}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Tache t, ThemeData theme, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('info', lang),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.construction_rounded,
              label: AppStrings.get('chantier', lang),
              value: _chantierNom(t.chantierId),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.flag_outlined,
              label: AppStrings.get('status', lang),
              value: AppStrings.get(t.statut, lang),
              valueColor: _statusColor(t.statut),
            ),
            if (t.priorite != null) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.priority_high_rounded,
                label: AppStrings.get('priority', lang),
                value: t.prioriteLabel,
                valueColor: t.prioriteColor,
              ),
            ],
            if (t.categorie != null) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.folder_outlined,
                label: AppStrings.get('category', lang),
                value: t.categorieLabel,
              ),
            ],
            if (t.description != null && t.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.notes_rounded,
                label: AppStrings.get('description', lang),
                value: t.description!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard(Tache t, ThemeData theme, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('date', lang),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: AppStrings.get('start_date', lang),
                    value: _formatDate(t.dateDebut),
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateBox(
                    label: AppStrings.get('end_date', lang),
                    value: _formatDate(t.dateFin),
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
                    label: AppStrings.get('actual_start', lang),
                    value: _formatDate(t.dateDebutReelle),
                    icon: Icons.play_arrow_outlined,
                    isReal: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateBox(
                    label: AppStrings.get('actual_end', lang),
                    value: _formatDate(t.dateFinReelle),
                    icon: Icons.check_outlined,
                    isReal: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoriqueCard(ThemeData theme, String lang) {
    if (_historique.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('history', lang),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._historique.take(10).map((h) {
              final action = h['action']?.toString() ?? '';
              final date = h['dateAction']?.toString() ?? '';
              IconData icon;
              Color color;
              switch (action) {
                case 'CREATION':
                  icon = Icons.add_circle_outline;
                  color = AppTheme.primary;
                  break;
                case 'DEMARRAGE':
                  icon = Icons.play_arrow_outlined;
                  color = AppTheme.statusEnCours;
                  break;
                case 'TERMINAISON':
                  icon = Icons.check_circle_outline;
                  color = AppTheme.statusTermine;
                  break;
                case 'AVANCEMENT':
                  icon = Icons.trending_up_outlined;
                  color = AppTheme.info;
                  break;
                case 'SUSPENSION':
                  icon = Icons.pause_circle_outline;
                  color = Colors.grey;
                  break;
                case 'REPRISE':
                  icon = Icons.play_circle_outline;
                  color = AppTheme.statusEnCours;
                  break;
                case 'MODIFICATION':
                  icon = Icons.edit_outlined;
                  color = AppTheme.primary;
                  break;
                default:
                  icon = Icons.edit_outlined;
                  color = theme.colorScheme.onSurfaceVariant;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (h['ancienneValeur'] != null &&
                              h['nouvelleValeur'] != null)
                            Text(
                              '${h['ancienneValeur']} → ${h['nouvelleValeur']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      date.length > 10 ? date.substring(0, 10) : date,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGETS INTERNES
// ============================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String value;
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
    final hasValue = value != '—';
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
            value,
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
