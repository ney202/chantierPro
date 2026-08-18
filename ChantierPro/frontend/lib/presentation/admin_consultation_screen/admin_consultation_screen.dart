import 'package:flutter/material.dart';

import '../../core/api/data_services.dart';
import '../../core/api/api_client.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';
import '../../core/models/alerte.dart';
import '../../core/models/chantier.dart';
import '../../core/models/depense.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';

enum ConsultationType { alertes, depenses }

/// Écran ADMIN de consultation (lecture seule) : alertes ou dépenses
/// de tous les chantiers, selon le [type] passé par la route.
class AdminConsultationScreen extends StatefulWidget {
  final ConsultationType type;
  const AdminConsultationScreen({super.key, required this.type});

  @override
  State<AdminConsultationScreen> createState() =>
      _AdminConsultationScreenState();
}

class _AdminConsultationScreenState extends State<AdminConsultationScreen> {
  bool _isLoading = true;
  String? _error;
  List<Alerte> _alertes = [];
  List<Depense> _depenses = [];
  List<Chantier> _chantiers = [];

  bool get _isAlertes => widget.type == ConsultationType.alertes;

  @override
  void initState() {
    super.initState();
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
        if (_isAlertes) AlerteService().getAll() else DepenseService().getAll(),
        ChantierService().getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        if (_isAlertes) {
          _alertes = (results[0] as List<Alerte>)
            ..sort((a, b) => b.id.compareTo(a.id));
        } else {
          _depenses = (results[0] as List<Depense>)
            ..sort((a, b) => b.id.compareTo(a.id));
        }
        _chantiers = results[1] as List<Chantier>;
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

  Future<void> _markAsRead(Alerte alerte) async {
    try {
      await AlerteService().markAsRead(alerte.id);
      if (!mounted) return;
      setState(() {
        _alertes.removeWhere((a) => a.id == alerte.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alerte marquée comme lue'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await AlerteService().markAllAsRead();
      if (!mounted) return;
      setState(() {
        _alertes.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les alertes ont été marquées comme lues'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(e))));
    }
  }

  String _chantierSymbol(int? id) {
    for (final c in _chantiers) {
      if (c.id == id) return c.symbol;
    }
    return '€';
  }

  String _chantierNom(int? id) {
    for (final c in _chantiers) {
      if (c.id == id) return c.nom;
    }
    return id == null ? '—' : 'Chantier #$id';
  }

  Color _alerteColor(String? statut) {
    switch ((statut ?? '').toLowerCase()) {
      case 'resolue':
      case 'résolue':
      case 'traitee':
      case 'traitée':
        return AppTheme.success;
      case 'en_cours':
        return AppTheme.statusEnAttente;
      default:
        return AppTheme.statusRetard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);

    final count = _isAlertes ? _alertes.length : _depenses.length;
    final deviseParChantier = {for (final c in _chantiers) c.id: c.devise};
    final totauxDepenses = <String, double>{};
    for (final d in _depenses) {
      final dev = deviseParChantier[d.chantierId] ?? 'EUR';
      totauxDepenses[dev] = (totauxDepenses[dev] ?? 0) + d.montant;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppBarWidget(
            title: _isAlertes ? s('alerts') : s('expenses'),
            subtitle: _isAlertes
                ? '$count ${s('in_total')}'
                : '$count ${s('in_total')} · ${formatTotalsByDevise(totauxDepenses)}',
            showBack: true,
            showAvatar: false,
            actions: _isAlertes && _alertes.isNotEmpty
                ? [
                    IconButton(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all),
                      tooltip: 'Tout marquer comme lu',
                    ),
                  ]
                : null,
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
                  : count == 0
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          _isAlertes
                              ? Icons.notifications_none_rounded
                              : Icons.receipt_long_outlined,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            _isAlertes ? s('no_alerts') : s('no_expenses'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: count,
                      itemBuilder: (context, index) => _isAlertes
                          ? _buildAlerteCard(theme, s, _alertes[index])
                          : _buildDepenseCard(theme, _depenses[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerteCard(
    ThemeData theme,
    String Function(String) s,
    Alerte a,
  ) {
    final color = _alerteColor(a.statut);
    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(31),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notification_important_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _chantierNom(a.chantierId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (a.statut != null && a.statut!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(31),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    a.statut!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 22),
                color: AppTheme.success,
                onPressed: () => _markAsRead(a),
                tooltip: 'Marquer comme lu',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(a.message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            a.dateCreation != null ? formatDate(a.dateCreation!) : '—',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepenseCard(ThemeData theme, Depense d) {
    return Container(
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.success.withAlpha(31),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppTheme.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.description?.isNotEmpty == true
                      ? d.description!
                      : _chantierNom(d.chantierId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_chantierNom(d.chantierId)} · ${d.dateDepense != null ? formatDate(d.dateDepense!) : '—'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMoney(d.montant, _chantierSymbol(d.chantierId)),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FONCTIONS UTILITAIRES
// ============================================================================

String formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String formatMoney(double amount, String symbol) {
  final formatted = amount.toStringAsFixed(2);
  return '$formatted $symbol';
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
