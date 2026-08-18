/// Miroir du DTO backend `RapportResponse`.
class Rapport {
  final int id;
  final String contenu;
  final DateTime? dateRapport;
  final int? chantierId;
  final int? auteurId;

  const Rapport({
    required this.id,
    required this.contenu,
    this.dateRapport,
    this.chantierId,
    this.auteurId,
  });

  factory Rapport.fromJson(Map<String, dynamic> json) => Rapport(
        id: (json['id'] as num).toInt(),
        contenu: json['contenu'] ?? '',
        dateRapport: json['dateRapport'] != null
            ? DateTime.tryParse(json['dateRapport'])
            : null,
        chantierId:
            json['chantierId'] != null ? (json['chantierId'] as num).toInt() : null,
        auteurId:
            json['auteurId'] != null ? (json['auteurId'] as num).toInt() : null,
      );
}
