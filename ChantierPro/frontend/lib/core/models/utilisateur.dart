/// Miroir du DTO backend `UtilisateurResponse`.
class Utilisateur {
  final int id;
  final String nom;
  final String email;
  final String? telephone;
  final String role; // ADMIN | CHEF_CHANTIER

  const Utilisateur({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone,
    required this.role,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) => Utilisateur(
        id: (json['id'] as num).toInt(),
        nom: json['nom'] ?? '',
        email: json['email'] ?? '',
        telephone: json['telephone'],
        role: json['role'] ?? 'CHEF_CHANTIER',
      );

  String get roleLabel =>
      role == 'ADMIN' ? 'Administrateur' : 'Chef de chantier';

  String get initials {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
