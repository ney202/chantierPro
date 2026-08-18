import 'package:flutter/material.dart';

class Chantier {
  final int id;
  final String nom;
  final String localisation;
  final String? description;
  final String? client;
  final String? devise;
  final DateTime? dateDebut;
  final DateTime? dateFinPrevue;
  final DateTime? dateDebutReelle;
  final DateTime? dateFinReelle;
  final double budget;
  final String statut;
  final int avancement;
  final bool suspendu;
  final int? chefId;
  final String? chefNom;
  final String symbol;

  // === NOUVEAUX CHAMPS GÉOLOCALISATION V2 ===
  final double? latitude;
  final double? longitude;
  final String? adresseComplete;
  // ==========================================

  // Flags calculés par le backend
  final bool canDemarrer;
  final bool canTerminer;
  final bool isEnRetard;
  final int joursRetard;
  final bool isAttention;

  // Stats tâches
  final int nbTachesTotal;
  final int nbTachesTerminees;
  final int nbTachesEnCours;
  final int nbTachesPlanifiees;
  final int nbTachesRetard;

  const Chantier({
    required this.id,
    required this.nom,
    required this.localisation,
    this.description,
    this.client,
    this.devise,
    this.dateDebut,
    this.dateFinPrevue,
    this.dateDebutReelle,
    this.dateFinReelle,
    required this.budget,
    required this.statut,
    this.avancement = 0,
    this.suspendu = false,
    this.chefId,
    this.chefNom,
    this.symbol = '€',
    // === V2 ===
    this.latitude,
    this.longitude,
    this.adresseComplete,
    // ==========
    this.canDemarrer = false,
    this.canTerminer = false,
    this.isEnRetard = false,
    this.joursRetard = 0,
    this.isAttention = false,
    this.nbTachesTotal = 0,
    this.nbTachesTerminees = 0,
    this.nbTachesEnCours = 0,
    this.nbTachesPlanifiees = 0,
    this.nbTachesRetard = 0,
  });

  factory Chantier.fromJson(Map<String, dynamic> json) => Chantier(
    id: (json['id'] as num).toInt(),
    nom: json['nom'] ?? '',
    localisation: json['localisation'] ?? '',
    description: json['description'],
    client: json['client'],
    devise: json['devise'],
    dateDebut: json['dateDebut'] != null
        ? DateTime.tryParse(json['dateDebut'])
        : null,
    dateFinPrevue: json['dateFinPrevue'] != null
        ? DateTime.tryParse(json['dateFinPrevue'])
        : null,
    dateDebutReelle: json['dateDebutReelle'] != null
        ? DateTime.tryParse(json['dateDebutReelle'])
        : null,
    dateFinReelle: json['dateFinReelle'] != null
        ? DateTime.tryParse(json['dateFinReelle'])
        : null,
    budget: json['budget'] != null ? (json['budget'] as num).toDouble() : 0,
    statut: _normalizeStatut(json['statut']),
    avancement: json['avancement'] != null
        ? (json['avancement'] as num).toInt()
        : 0,
    suspendu: json['suspendu'] == true,
    chefId: json['chefId'] != null ? (json['chefId'] as num).toInt() : null,
    chefNom: json['chefNom'],
    symbol: json['symbol']?.toString() ?? '€',
    // === V2 ===
    latitude: json['latitude'] != null
        ? (json['latitude'] as num).toDouble()
        : null,
    longitude: json['longitude'] != null
        ? (json['longitude'] as num).toDouble()
        : null,
    adresseComplete: json['adresseComplete'],
    // ==========
    canDemarrer: json['canDemarrer'] == true,
    canTerminer: json['canTerminer'] == true,
    isEnRetard: json['isEnRetard'] == true,
    joursRetard: json['joursRetard'] != null
        ? (json['joursRetard'] as num).toInt()
        : 0,
    isAttention: json['isAttention'] == true,
    nbTachesTotal: json['nbTachesTotal'] != null
        ? (json['nbTachesTotal'] as num).toInt()
        : 0,
    nbTachesTerminees: json['nbTachesTerminees'] != null
        ? (json['nbTachesTerminees'] as num).toInt()
        : 0,
    nbTachesEnCours: json['nbTachesEnCours'] != null
        ? (json['nbTachesEnCours'] as num).toInt()
        : 0,
    nbTachesPlanifiees: json['nbTachesPlanifiees'] != null
        ? (json['nbTachesPlanifiees'] as num).toInt()
        : 0,
    nbTachesRetard: json['nbTachesRetard'] != null
        ? (json['nbTachesRetard'] as num).toInt()
        : 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'localisation': localisation,
    'description': description,
    'client': client,
    'devise': devise,
    'dateDebut': dateDebut?.toIso8601String().substring(0, 10),
    'dateFinPrevue': dateFinPrevue?.toIso8601String().substring(0, 10),
    'budget': budget,
    'chefId': chefId,
    'latitude': latitude,
    'longitude': longitude,
    'adresseComplete': adresseComplete,
  };

  static String _normalizeStatut(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase().replaceAll(' ', '_');
    const known = [
      'en_cours',
      'planifie',
      'retard',
      'termine',
      'en_attente',
      'attention',
      'suspendu',
    ];
    if (known.contains(s)) return s;
    if (s.contains('cours')) return 'en_cours';
    if (s.contains('plan')) return 'planifie';
    if (s.contains('retard')) return 'retard';
    if (s.contains('termin')) return 'termine';
    if (s.contains('attente')) return 'en_attente';
    if (s.contains('attention')) return 'attention';
    if (s.contains('suspend')) return 'suspendu';
    return 'planifie';
  }

  bool get isTermine => statut == 'termine';
  bool get isEnCours => statut == 'en_cours';
  bool get isPlanifie => statut == 'planifie';
  bool get isSuspendu => suspendu;

  /// Retourne l'adresse à afficher (priorité à l'adresse complète géocodée)
  String get displayAddress => adresseComplete ?? localisation;

  /// Vérifie si des coordonnées GPS sont disponibles
  bool get hasCoordinates => latitude != null && longitude != null;
}
