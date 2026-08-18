/// Permet à un écran (ex: dashboard) de demander à un autre écran
/// (ex: liste des chantiers, tâches) d'appliquer un filtre à l'arrivée.
/// L'écran cible consomme la valeur dans son build puis la remet à null.
class PendingFilters {
  static final PendingFilters _instance = PendingFilters._internal();
  factory PendingFilters() => _instance;
  PendingFilters._internal();

  /// Filtre à appliquer sur la liste des chantiers ('en_cours', 'retard'...).
  String? chantierFilter;

  /// Filtre à appliquer sur la liste des tâches.
  String? tacheFilter;

  String? takeChantierFilter() {
    final v = chantierFilter;
    chantierFilter = null;
    return v;
  }

  String? takeTacheFilter() {
    final v = tacheFilter;
    tacheFilter = null;
    return v;
  }
}
