import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_session.dart';
import '../../../core/api/data_services.dart';
import '../../../core/api/refresh_bus.dart';
import '../../../core/app_state.dart';
import '../../../core/app_strings.dart';
import '../../../theme/app_theme.dart';

class AddChantierBottomSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  const AddChantierBottomSheet({super.key, this.onCreated});

  @override
  State<AddChantierBottomSheet> createState() => _AddChantierBottomSheetState();
}

class _AddChantierBottomSheetState extends State<AddChantierBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();
  final _budgetController = TextEditingController();
  final _searchController = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isSubmitting = false;

  // === V2 : Carte & Géolocalisation — OpenStreetMap ===
  final _mapController = MapController();
  LatLng _currentMapPosition = const LatLng(
    48.8566,
    2.3522,
  ); // Paris par défaut
  String? _selectedAddress;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _permissionDenied = false;
  Timer? _debounce;
  // =====================================================

  @override
  void dispose() {
    _debounce?.cancel();
    _nomController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    _budgetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Permissions & Localisation ──
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le service de localisation est désactivé.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _permissionDenied = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de localisation refusée.'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _permissionDenied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission refusée définitivement. Activez-la dans les paramètres.',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _centerOnUserLocation() async {
    setState(() => _isLocating = true);
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() => _isLocating = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final target = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentMapPosition = target;
        _permissionDenied = false;
      });
      _mapController.move(target, 16);
      await _reverseGeocode(target);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'obtenir la position actuelle.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Géocodage ──
  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        setState(() => _currentMapPosition = target);
        _mapController.move(target, 16);
        await _reverseGeocode(target);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adresse introuvable : "$query"'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address = [
          p.street,
          p.postalCode,
          p.locality,
          p.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        setState(() {
          _selectedAddress = address;
          _adresseController.text = address;
        });
      }
    } catch (_) {
      // Silencieux — l'utilisateur peut saisir manuellement
    }
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _currentMapPosition = camera.center;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(camera.center);
    });
  }

  // ── Dates ──
  Future<void> _pickDate(bool isDebut) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? now : (now.add(const Duration(days: 90))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Sélectionner';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // ── Soumission ──
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner les dates de début et de fin'),
        ),
      );
      return;
    }

    final chefId = AuthSession().user?.id;
    if (chefId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur non connecté'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ChantierService().create(
        nom: _nomController.text.trim(),
        localisation: _adresseController.text.trim(),
        description: _descriptionController.text.trim(),
        dateDebut: _dateDebut,
        dateFinPrevue: _dateFin,
        budget: double.parse(_budgetController.text),
        chefId: chefId,
        // === V2 : Coordonnées GPS ===
        latitude: _currentMapPosition.latitude,
        longitude: _currentMapPosition.longitude,
        adresseComplete: _selectedAddress ?? _adresseController.text.trim(),
        // =============================
      );
      RefreshBus().ping();
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.getP(
                'chantier_created',
                AppState().locale.languageCode,
                {'x': _nomController.text},
              ),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppState().locale.languageCode;
    String s(String k) => AppStrings.get(k, lang);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_business_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  s('new_chantier'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── NOM ───
                    TextFormField(
                      controller: _nomController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: '${s('chantier_name')} *',
                        hintText: 'ex: Tour Résidentielle Alpina',
                        prefixIcon: Icon(
                          Icons.construction_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s('error_required')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    // ─── DESCRIPTION ───
                    TextFormField(
                      controller: _descriptionController,
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: s('description'),
                        hintText: 'ex: Construction d\'un immeuble de 5 étages',
                        prefixIcon: Icon(
                          Icons.description_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ═══════════════════════════════════════════════════════
                    // V2 : SÉLECTION GÉOGRAPHIQUE SUR CARTE — OpenStreetMap
                    // ═══════════════════════════════════════════════════════
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.map_outlined,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Localisation sur la carte',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Barre de recherche d'adresse
                          TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _searchAddress,
                            decoration: InputDecoration(
                              hintText: 'Rechercher une adresse...',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              suffixIcon: _isSearching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                      onPressed: () => _searchAddress(
                                        _searchController.text,
                                      ),
                                    ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Carte interactive OpenStreetMap
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              height: 240,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _currentMapPosition,
                                      initialZoom: 14,
                                      onPositionChanged: _onPositionChanged,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.example.chantierpro',
                                      ),
                                    ],
                                  ),
                                  // Marqueur centré (overlay)
                                  IgnorePointer(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            'Déplacez pour ajuster',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Icon(
                                          Icons.location_on_rounded,
                                          color: AppTheme.primary,
                                          size: 40,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 28),
                                      ],
                                    ),
                                  ),
                                  // Bouton position actuelle
                                  Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: FloatingActionButton.small(
                                      heroTag: 'btn_loc_add',
                                      onPressed: _isLocating
                                          ? null
                                          : _centerOnUserLocation,
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.primary,
                                      elevation: 3,
                                      child: _isLocating
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppTheme.primary,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location_rounded,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Adresse confirmée
                          if (_selectedAddress != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.success.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.success,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedAddress!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (_permissionDenied)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Localisation non disponible. Vous pouvez rechercher une adresse manuellement.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ═══════════════════════════════════════════════════════
                    const SizedBox(height: 14),

                    // ─── ADRESSE (affichage/édition manuelle) ───
                    TextFormField(
                      controller: _adresseController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: '${s('address')} *',
                        hintText: 'ex: 14 Rue de la Paix, Lyon 69002',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s('error_required')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    // ─── BUDGET ───
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: '${s('budget')} *',
                        hintText: 'ex: 850000',
                        prefixIcon: Icon(
                          Icons.euro_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        suffixText: '€',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return s('error_required');
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return s('invalid_amount');
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // ─── DATES ───
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: s('start_date'),
                            value: _formatDate(_dateDebut),
                            onTap: () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DatePickerField(
                            label: s('end_date'),
                            value: _formatDate(_dateFin),
                            onTap: () => _pickDate(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
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
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value != 'Sélectionner';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.3)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
