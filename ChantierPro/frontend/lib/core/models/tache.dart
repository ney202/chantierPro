import 'package:flutter/material.dart';

class Tache {
  final int id;
  final String titre;
  final String? description;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? dateDebutReelle;
  final DateTime? dateFinReelle;
  final String statut;
  final int avancement;
  final String? priorite;
  final String? categorie;
  final int? chantierId;
  final String? chantierNom;
  final bool suspendu;
  final int joursRetard;
  final bool alerteEcheance;
  final bool canDemarrer;
  final bool canTerminer;
  final bool canUpdateAvancement;
  final bool isEnRetard;
  final bool isAttention;

  const Tache({
    required this.id,
    required this.titre,
    this.description,
    this.dateDebut,
    this.dateFin,
    this.dateDebutReelle,
    this.dateFinReelle,
    required this.statut,
    this.avancement = 0,
    this.priorite,
    this.categorie,
    this.chantierId,
    this.chantierNom,
    this.suspendu = false,
    this.joursRetard = 0,
    this.alerteEcheance = false,
    this.canDemarrer = false,
    this.canTerminer = false,
    this.canUpdateAvancement = false,
    this.isEnRetard = false,
    this.isAttention = false,
  });

  factory Tache.fromJson(Map<String, dynamic> json) => Tache(
    id: (json['id'] as num).toInt(),
    titre: json['titre'] ?? '',
    description: json['description'],
    dateDebut: json['dateDebut'] != null
        ? DateTime.tryParse(json['dateDebut'])
        : null,
    dateFin: json['dateFin'] != null
        ? DateTime.tryParse(json['dateFin'])
        : null,
    dateDebutReelle: json['dateDebutReelle'] != null
        ? DateTime.tryParse(json['dateDebutReelle'])
        : null,
    dateFinReelle: json['dateFinReelle'] != null
        ? DateTime.tryParse(json['dateFinReelle'])
        : null,
    statut: _normalizeStatut(json['statut']),
    avancement: json['avancement'] != null
        ? (json['avancement'] as num).toInt()
        : 0,
    priorite: json['priorite']?.toString().toLowerCase(),
    categorie: json['categorie']?.toString().toLowerCase(),
    chantierId: json['chantierId'] != null
        ? (json['chantierId'] as num).toInt()
        : null,
    chantierNom: json['chantierNom'],
    suspendu: json['suspendu'] == true,
    joursRetard: json['joursRetard'] != null
        ? (json['joursRetard'] as num).toInt()
        : 0,
    alerteEcheance: json['alerteEcheance'] == true,
    canDemarrer: json['canDemarrer'] == true,
    canTerminer: json['canTerminer'] == true,
    canUpdateAvancement: json['canUpdateAvancement'] == true,
    isEnRetard: json['isEnRetard'] == true,
    isAttention: json['isAttention'] == true,
  );

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

  bool get isTerminee => statut == 'termine';
  bool get isEnCours => statut == 'en_cours';
  bool get isPlanifiee => statut == 'planifie';
  bool get isSuspendue => suspendu;

  Color get prioriteColor {
    switch (priorite) {
      case 'critique':
        return const Color(0xFFE53935);
      case 'elevee':
        return const Color(0xFFFF9800);
      case 'normale':
        return const Color(0xFF2196F3);
      case 'faible':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String get prioriteLabel {
    switch (priorite) {
      case 'critique':
        return 'Critique';
      case 'elevee':
        return 'Élevée';
      case 'normale':
        return 'Normale';
      case 'faible':
        return 'Faible';
      default:
        return 'Normale';
    }
  }

  String get categorieLabel {
    switch (categorie) {
      case 'terrassement':
        return 'Terrassement';
      case 'fondation':
        return 'Fondation';
      case 'maconnerie':
        return 'Maçonnerie';
      case 'beton':
        return 'Béton';
      case 'electricite':
        return 'Électricité';
      case 'plomberie':
        return 'Plomberie';
      case 'menuiserie':
        return 'Menuiserie';
      case 'peinture':
        return 'Peinture';
      case 'finition':
        return 'Finition';
      case 'autre':
        return 'Autre';
      default:
        return categorie ?? 'Non classé';
    }
  }
}
