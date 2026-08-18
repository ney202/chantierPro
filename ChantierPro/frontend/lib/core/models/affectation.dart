/// Miroir du DTO backend `AffectationResponse`.
class Affectation {
  final int id;
  final int? utilisateurId;
  final int? chantierId;
  final DateTime? dateAffectation;

  const Affectation({
    required this.id,
    this.utilisateurId,
    this.chantierId,
    this.dateAffectation,
  });

  factory Affectation.fromJson(Map<String, dynamic> json) => Affectation(
    id: (json['id'] as num).toInt(),
    utilisateurId: json['utilisateurId'] != null
        ? (json['utilisateurId'] as num).toInt()
        : null,
    chantierId: json['chantierId'] != null
        ? (json['chantierId'] as num).toInt()
        : null,
    dateAffectation: json['dateAffectation'] != null
        ? DateTime.tryParse(json['dateAffectation'])
        : null,
  );
}
