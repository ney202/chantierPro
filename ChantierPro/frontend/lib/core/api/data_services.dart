import 'package:dio/dio.dart';

import 'api_client.dart';
import '../models/alerte.dart';
import '../models/chantier.dart';
import '../models/tache.dart';
import '../models/rapport.dart';
import '../models/photo.dart';
import '../models/depense.dart';
import '../models/utilisateur.dart';

List<T> _asList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  final list = data is Map ? (data['content'] as List? ?? []) : (data as List);
  return list
      .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// /api/chantiers
class ChantierService {
  final _client = ApiClient();

  Future<List<Chantier>> getAll() async {
    final res = await _client.dio.get('/chantiers');
    return _asList(res.data, Chantier.fromJson);
  }

  Future<Chantier> getById(int id) async {
    final res = await _client.dio.get('/chantiers/$id');
    return Chantier.fromJson(res.data);
  }

  Future<Chantier> create({
    required String nom,
    required String localisation,
    String? description,
    String? client,
    String? devise,
    DateTime? dateDebut,
    DateTime? dateFinPrevue,
    required double budget,
    required int chefId,
    double? latitude,
    double? longitude,
    String? adresseComplete,
  }) async {
    final res = await _client.dio.post(
      '/chantiers',
      data: {
        'nom': nom,
        'localisation': localisation,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (client != null && client.isNotEmpty) 'client': client,
        if (devise != null) 'devise': devise,
        if (dateDebut != null)
          'dateDebut': dateDebut.toIso8601String().substring(0, 10),
        if (dateFinPrevue != null)
          'dateFinPrevue': dateFinPrevue.toIso8601String().substring(0, 10),
        'budget': budget,
        'chefId': chefId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (adresseComplete != null && adresseComplete.isNotEmpty)
          'adresseComplete': adresseComplete,
      },
    );
    return Chantier.fromJson(res.data);
  }

  Future<Chantier> update({
    required int id,
    required String nom,
    required String localisation,
    String? description,
    String? client,
    String? devise,
    DateTime? dateDebut,
    DateTime? dateFinPrevue,
    required double budget,
    required int chefId,
    double? latitude,
    double? longitude,
    String? adresseComplete,
  }) async {
    final res = await _client.dio.put(
      '/chantiers/$id',
      data: {
        'nom': nom,
        'localisation': localisation,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (client != null && client.isNotEmpty) 'client': client,
        if (devise != null) 'devise': devise,
        if (dateDebut != null)
          'dateDebut': dateDebut.toIso8601String().substring(0, 10),
        if (dateFinPrevue != null)
          'dateFinPrevue': dateFinPrevue.toIso8601String().substring(0, 10),
        'budget': budget,
        'chefId': chefId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (adresseComplete != null && adresseComplete.isNotEmpty)
          'adresseComplete': adresseComplete,
      },
    );
    return Chantier.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/chantiers/$id');
  }

  Future<Chantier> demarrer(int id) async {
    final res = await _client.dio.post('/chantiers/$id/demarrer');
    return Chantier.fromJson(res.data);
  }

  Future<Chantier> terminer(int id) async {
    final res = await _client.dio.post('/chantiers/$id/terminer');
    return Chantier.fromJson(res.data);
  }

  Future<Chantier> suspendre(int id) async {
    final res = await _client.dio.post('/chantiers/$id/suspendre');
    return Chantier.fromJson(res.data);
  }

  Future<Chantier> reprendre(int id) async {
    final res = await _client.dio.post('/chantiers/$id/reprendre');
    return Chantier.fromJson(res.data);
  }
}

/// /api/taches
class TacheService {
  final _client = ApiClient();

  Future<List<Tache>> getAll({int? chantierId}) async {
    if (chantierId != null) {
      final res = await _client.dio.get(
        '/taches/search',
        queryParameters: {'chantierId': chantierId},
      );
      return _asList(res.data, Tache.fromJson);
    }
    final res = await _client.dio.get('/taches');
    return _asList(res.data, Tache.fromJson);
  }

  Future<Tache> getById(int id) async {
    final res = await _client.dio.get('/taches/$id');
    return Tache.fromJson(res.data);
  }

  Future<Tache> create({
    required String titre,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? priorite,
    String? categorie,
    required int chantierId,
  }) async {
    final res = await _client.dio.post(
      '/taches',
      data: {
        'titre': titre,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (dateDebut != null)
          'dateDebut': dateDebut.toIso8601String().substring(0, 10),
        if (dateFin != null)
          'dateFin': dateFin.toIso8601String().substring(0, 10),
        if (priorite != null) 'priorite': priorite,
        if (categorie != null) 'categorie': categorie,
        'chantierId': chantierId,
      },
    );
    return Tache.fromJson(res.data);
  }

  Future<Tache> update({
    required int id,
    required String titre,
    String? description,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? priorite,
    String? categorie,
    required int chantierId,
  }) async {
    final res = await _client.dio.put(
      '/taches/$id',
      data: {
        'titre': titre,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (dateDebut != null)
          'dateDebut': dateDebut.toIso8601String().substring(0, 10),
        if (dateFin != null)
          'dateFin': dateFin.toIso8601String().substring(0, 10),
        if (priorite != null) 'priorite': priorite,
        if (categorie != null) 'categorie': categorie,
        'chantierId': chantierId,
      },
    );
    return Tache.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/taches/$id');
  }

  Future<Tache> demarrer(int id) async {
    final res = await _client.dio.post('/taches/$id/demarrer');
    return Tache.fromJson(res.data);
  }

  Future<Tache> updateAvancement(int id, int avancement) async {
    final res = await _client.dio.post(
      '/taches/$id/avancement',
      data: {'avancement': avancement},
    );
    return Tache.fromJson(res.data);
  }

  Future<Tache> terminer(int id) async {
    final res = await _client.dio.post('/taches/$id/terminer');
    return Tache.fromJson(res.data);
  }

  Future<Tache> suspendre(int id) async {
    final res = await _client.dio.post('/taches/$id/suspendre');
    return Tache.fromJson(res.data);
  }

  Future<Tache> reprendre(int id) async {
    final res = await _client.dio.post('/taches/$id/reprendre');
    return Tache.fromJson(res.data);
  }

  Future<List<Map<String, dynamic>>> getHistorique(int id) async {
    final res = await _client.dio.get('/taches/$id/historique');
    final list = res.data as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

/// /api/rapports
class RapportService {
  final _client = ApiClient();

  Future<List<Rapport>> getAll({int? chantierId}) async {
    if (chantierId != null) {
      final res = await _client.dio.get(
        '/rapports/search',
        queryParameters: {'chantierId': chantierId},
      );
      return _asList(res.data, Rapport.fromJson);
    }
    final res = await _client.dio.get('/rapports');
    return _asList(res.data, Rapport.fromJson);
  }

  Future<Rapport> create({
    required String contenu,
    DateTime? dateRapport,
    required int chantierId,
    required int auteurId,
  }) async {
    final res = await _client.dio.post(
      '/rapports',
      data: {
        'contenu': contenu,
        if (dateRapport != null)
          'dateRapport': dateRapport.toIso8601String().substring(0, 10),
        'chantierId': chantierId,
        'auteurId': auteurId,
      },
    );
    return Rapport.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/rapports/$id');
  }
}

/// /api/photos
class PhotoService {
  final _client = ApiClient();

  Future<List<Photo>> getAll({int? rapportId}) async {
    if (rapportId != null) {
      final res = await _client.dio.get(
        '/photos/search',
        queryParameters: {'rapportId': rapportId},
      );
      return _asList(res.data, Photo.fromJson);
    }
    final res = await _client.dio.get('/photos');
    return _asList(res.data, Photo.fromJson);
  }

  Future<Photo> upload({
    required String filePath,
    required int rapportId,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'rapportId': rapportId,
    });
    final res = await _client.dio.post('/photos/upload', data: formData);
    return Photo.fromJson(res.data);
  }

  /// Suppression d'une photo — réservée à l'admin côté backend
  /// (le bouton n'est de toute façon affiché que pour l'admin côté UI,
  /// mais le backend doit revalider le rôle).
  Future<void> delete(int id) async {
    await _client.dio.delete('/photos/$id');
  }
}

/// /api/depenses
class DepenseService {
  final _client = ApiClient();

  Future<List<Depense>> getAll() async {
    final res = await _client.dio.get('/depenses');
    return _asList(res.data, Depense.fromJson);
  }

  Future<Depense> create({
    required double montant,
    String? description,
    DateTime? dateDepense,
    required int chantierId,
  }) async {
    final res = await _client.dio.post(
      '/depenses',
      data: {
        'montant': montant,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (dateDepense != null)
          'dateDepense': dateDepense.toIso8601String().substring(0, 10),
        'chantierId': chantierId,
      },
    );
    return Depense.fromJson(res.data);
  }
}

/// /api/utilisateurs
class UtilisateurApiService {
  final _client = ApiClient();

  Future<List<Utilisateur>> getAll() async {
    final res = await _client.dio.get('/utilisateurs');
    return _asList(res.data, Utilisateur.fromJson);
  }
}

/// /api/alertes
class AlerteService {
  final _client = ApiClient();

  Future<List<Alerte>> getAll() async {
    final res = await _client.dio.get('/alertes');
    return _asList(res.data, Alerte.fromJson);
  }

  Future<Alerte> getById(int id) async {
    final res = await _client.dio.get('/alertes/$id');
    return Alerte.fromJson(res.data);
  }

  Future<Alerte> create({
    required String message,
    DateTime? dateCreation,
    String? statut,
    bool? lu,
    required int chantierId,
  }) async {
    final res = await _client.dio.post(
      '/alertes',
      data: {
        'message': message,
        if (dateCreation != null)
          'dateCreation': dateCreation.toIso8601String(),
        if (statut != null) 'statut': statut,
        if (lu != null) 'lu': lu,
        'chantierId': chantierId,
      },
    );
    return Alerte.fromJson(res.data);
  }

  Future<Alerte> update({
    required int id,
    required String message,
    DateTime? dateCreation,
    String? statut,
    bool? lu,
    required int chantierId,
  }) async {
    final res = await _client.dio.put(
      '/alertes/$id',
      data: {
        'message': message,
        if (dateCreation != null)
          'dateCreation': dateCreation.toIso8601String(),
        if (statut != null) 'statut': statut,
        if (lu != null) 'lu': lu,
        'chantierId': chantierId,
      },
    );
    return Alerte.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/alertes/$id');
  }

  Future<void> markAsRead(int id) async {
    await _client.dio.patch('/alertes/$id/lu');
  }

  Future<void> markAllAsRead() async {
    await _client.dio.patch('/alertes/lu/all');
  }

  Future<int> countUnread() async {
    final res = await _client.dio.get('/alertes/count/unread');
    return (res.data as num).toInt();
  }

  Future<List<Alerte>> search({String? statut, int? chantierId}) async {
    final res = await _client.dio.get(
      '/alertes/search',
      queryParameters: {
        if (statut != null) 'statut': statut,
        if (chantierId != null) 'chantierId': chantierId,
      },
    );
    return _asList(res.data, Alerte.fromJson);
  }
}
