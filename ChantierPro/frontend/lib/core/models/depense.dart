class Depense {
  final int id;
  final double montant;
  final String? description;
  final DateTime? dateDepense;
  final int? chantierId;

  const Depense({
    required this.id,
    required this.montant,
    this.description,
    this.dateDepense,
    this.chantierId,
  });

  factory Depense.fromJson(Map<String, dynamic> json) => Depense(
    id: (json['id'] as num).toInt(),
    montant: (json['montant'] as num).toDouble(),
    description: json['description'],
    dateDepense: json['dateDepense'] != null
        ? DateTime.tryParse(json['dateDepense'])
        : null,
    chantierId: json['chantierId'] != null
        ? (json['chantierId'] as num).toInt()
        : null,
  );
}
