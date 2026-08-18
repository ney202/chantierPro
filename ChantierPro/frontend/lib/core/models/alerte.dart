/// Miroir du DTO backend `AlerteResponse`.
class Alerte {
  final int id;
  final String message;
  final DateTime? dateCreation;
  final String? statut;
  final bool? lu;
  final int? chantierId;

  const Alerte({
    required this.id,
    required this.message,
    this.dateCreation,
    this.statut,
    this.lu,
    this.chantierId,
  });

  factory Alerte.fromJson(Map<String, dynamic> json) => Alerte(
    id: (json['id'] as num).toInt(),
    message: json['message'] ?? '',
    dateCreation: json['dateCreation'] != null
        ? DateTime.tryParse(json['dateCreation'])
        : null,
    statut: json['statut'],
    lu: json['lu'] as bool?,
    chantierId: json['chantierId'] != null
        ? (json['chantierId'] as num).toInt()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'dateCreation': dateCreation?.toIso8601String(),
    'statut': statut,
    'lu': lu,
    'chantierId': chantierId,
  };
}
