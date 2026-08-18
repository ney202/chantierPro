import '../models/chantier.dart';
import '../models/depense.dart';
import '../models/tache.dart';

/// Convertit un [Chantier] du backend vers la structure Map
/// attendue par les écrans (liste, détail, dashboard).
Map<String, dynamic> chantierToUiMap(
  Chantier c, {
  List<Tache> taches = const [],
  List<Depense> depenses = const [],
}) {
  final chantierTaches = taches.where((t) => t.chantierId == c.id).toList();
  final nbTaches = chantierTaches.length;
  final terminees = chantierTaches.where((t) => t.isTerminee).toList().length;

  final progress = (c.avancement ?? 0) / 100.0;

  final consomme = depenses
      .where((d) => d.chantierId == c.id)
      .fold<double>(0, (sum, d) => sum + d.montant);

  return {
    'id': c.id,
    'name': c.nom,
    'description': 'Chantier ${c.nom} — ${c.localisation}',
    'address': c.localisation,
    'status': c.statut,
    'budget': c.budget,
    'budgetConsomme': consomme,
    'dateDebut': c.dateDebut != null ? formatDate(c.dateDebut!) : '—',
    'dateFin': c.dateFinPrevue != null ? formatDate(c.dateFinPrevue!) : '—',
    'progress': progress,
    'chefChantier': c.chefNom ?? '—',
    'nbTaches': nbTaches,
    'tachesTerminees': terminees,
    'avancement': c.avancement ?? 0,
    'symbol': c.symbol,
    'devise': c.devise,
  };
}

String formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String formatMoney(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf €';
}

String formatMoneyWithSymbol(double v, String symbol) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf $symbol';
}

String formatMoneyCompact(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M€';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K€';
  return '${v.toStringAsFixed(0)}€';
}

String formatMoneyCompactWithSymbol(double v, String symbol) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M$symbol';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K$symbol';
  return '${v.toStringAsFixed(0)}$symbol';
}

String formatTotalsByDevise(Map<String, double> totaux) {
  if (totaux.isEmpty) return '';
  return totaux.entries
      .map((e) => '${formatMoney(e.value)} ${e.key}')
      .join(' · ');
}
