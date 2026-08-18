import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/admin_services.dart';
import '../../core/api/api_client.dart';
import '../../core/api/refresh_bus.dart';
import '../../core/app_state.dart';
import '../../core/app_strings.dart';
import '../../core/models/utilisateur.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';

/// Écran ADMIN : gestion des comptes Chef de chantier.
/// CRUD complet via /api/utilisateurs (réservé ADMIN).
class AdminChefsScreen extends StatefulWidget {
  const AdminChefsScreen({super.key});

  @override
  State<AdminChefsScreen> createState() => _AdminChefsScreenState();
}

class _AdminChefsScreenState extends State<AdminChefsScreen> {
  final _service = UtilisateurAdminService();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<Utilisateur> _chefs = [];
  String _query = '';

  // ── Filtres avancés ──
  String? _filterNom;
  String? _filterTelephone;

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
      final users = await _service.getAll();
      if (!mounted) return;
      setState(() {
        _chefs = users.where((u) => u.role == 'CHEF_CHANTIER').toList()
          ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
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

  List<Utilisateur> get _filtered {
    var filtered = _chefs;

    // Recherche rapide (barre de recherche)
    if (_query.isNotEmpty) {
      final q = _normalizeText(_query);
      filtered = filtered.where((u) {
        return _normalizeText(u.nom).contains(q) ||
            _normalizeText(u.email).contains(q) ||
            _normalizeText(u.telephone ?? '').contains(q);
      }).toList();
    }

    // Filtre avancé : nom
    if (_filterNom != null && _filterNom!.isNotEmpty) {
      final n = _normalizeText(_filterNom!);
      filtered = filtered.where((u) {
        return _normalizeText(u.nom).contains(n);
      }).toList();
    }

    // Filtre avancé : téléphone
    if (_filterTelephone != null && _filterTelephone!.isNotEmpty) {
      final t = _normalizeText(_filterTelephone!);
      filtered = filtered.where((u) {
        return _normalizeText(u.telephone ?? '').contains(t);
      }).toList();
    }

    return filtered;
  }

  bool get _hasActiveFilters =>
      (_filterNom != null && _filterNom!.isNotEmpty) ||
      (_filterTelephone != null && _filterTelephone!.isNotEmpty);

  void _clearAdvancedFilters() {
    setState(() {
      _filterNom = null;
      _filterTelephone = null;
    });
  }

  void _showFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);

    String tempNom = _filterNom ?? '';
    String tempTelephone = _filterTelephone ?? '';

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
                      initialValue: tempNom,
                      onChanged: (v) => tempNom = v,
                      decoration: InputDecoration(
                        labelText: s('last_name') ?? 'Nom',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: tempTelephone,
                      onChanged: (v) => tempTelephone = v,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: s('phone') ?? 'Téléphone',
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempNom = '';
                                tempTelephone = '';
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
                                _filterNom = tempNom.isEmpty ? null : tempNom;
                                _filterTelephone = tempTelephone.isEmpty
                                    ? null
                                    : tempTelephone;
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

  void _showChefSheet({Utilisateur? chef}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChefFormSheet(
        chef: chef,
        onSaved: () {
          RefreshBus().ping();
          _loadData();
        },
      ),
    );
  }

  Future<void> _confirmDelete(Utilisateur chef) async {
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s('confirm_delete')),
        content: Text(
          AppStrings.getP('delete_chef_warning', lang, {'x': chef.nom}),
        ),
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
      await _service.delete(chef.id);
      RefreshBus().ping();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s('chef_deleted')),
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
            title: s('manage_chefs'),
            subtitle: '${_chefs.length} ${s('site_managers').toLowerCase()}',
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
                  ? _ErrorView(
                      message: _error!,
                      retryLabel: s('retry'),
                      onRetry: _loadData,
                    )
                  : filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          Icons.engineering_outlined,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            s('no_chefs'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final chef = filtered[index];
                        return _ChefCard(
                          chef: chef,
                          onEdit: () => _showChefSheet(chef: chef),
                          onDelete: () => _confirmDelete(chef),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChefSheet(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          s('add_chef'),
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
              onChanged: (v) => setState(() => _query = v),
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
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
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

    if (_filterNom != null && _filterNom!.isNotEmpty) {
      chips.add(
        _FilterChip(
          label: '${s('last_name') ?? 'Nom'}: $_filterNom',
          onRemove: () {
            setState(() => _filterNom = null);
          },
        ),
      );
    }
    if (_filterTelephone != null && _filterTelephone!.isNotEmpty) {
      chips.add(
        _FilterChip(
          label: '${s('phone') ?? 'Téléphone'}: $_filterTelephone',
          onRemove: () {
            setState(() => _filterTelephone = null);
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

class _ChefCard extends StatelessWidget {
  final Utilisateur chef;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChefCard({
    required this.chef,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Text(
            chef.initials,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          chef.nom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chef.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (chef.telephone != null && chef.telephone!.isNotEmpty)
              Text(
                chef.telephone!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppTheme.error,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(retryLabel),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ),
      ],
    );
  }
}

/// Formulaire création/édition d'un chef (bottom sheet, style existant).
class _ChefFormSheet extends StatefulWidget {
  final Utilisateur? chef;
  final VoidCallback onSaved;

  const _ChefFormSheet({this.chef, required this.onSaved});

  @override
  State<_ChefFormSheet> createState() => _ChefFormSheetState();
}

class _ChefFormSheetState extends State<_ChefFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telCtrl;
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;

  bool get _isEdit => widget.chef != null;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.chef?.nom ?? '');
    _emailCtrl = TextEditingController(text: widget.chef?.email ?? '');
    _telCtrl = TextEditingController(text: widget.chef?.telephone ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await UtilisateurAdminService().update(
          id: widget.chef!.id,
          nom: _nomCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          telephone: _telCtrl.text.trim(),
          motDePasse: _passwordCtrl.text,
        );
      } else {
        await UtilisateurAdminService().create(
          nom: _nomCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          telephone: _telCtrl.text.trim(),
          motDePasse: _passwordCtrl.text,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? s('chef_updated') : s('chef_created')),
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
                _isEdit ? s('edit_chef') : s('add_chef'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: '${s('last_name')} *',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s('error_required')
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '${s('email')} *',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return s('error_required');
                  if (!v.contains('@')) return s('invalid_email');
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: s('phone'),
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '${s('password')} *',
                  helperText: _isEdit ? s('password_required_on_update') : null,
                  helperMaxLines: 2,
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return s('error_required');
                  if (v.length < 8) return s('password_min8');
                  return null;
                },
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
