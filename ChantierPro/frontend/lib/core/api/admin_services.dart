import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/alerte.dart';
import '../models/affectation.dart';
import '../models/utilisateur.dart';

List<T> _asList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  final list = data is Map ? (data['content'] as List? ?? []) : (data as List);
  return list
      .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// /api/affectations
class AffectationService {
  final _client = ApiClient();

  Future<List<Affectation>> getAll() async {
    final res = await _client.dio.get('/affectations');
    return _asList(res.data, Affectation.fromJson);
  }

  Future<List<Affectation>> getByChantier(int chantierId) async {
    final res = await _client.dio.get(
      '/affectations/search',
      queryParameters: {'chantierId': chantierId},
    );
    return _asList(res.data, Affectation.fromJson);
  }

  Future<Affectation> create({
    required int utilisateurId,
    required int chantierId,
    DateTime? dateAffectation,
  }) async {
    final res = await _client.dio.post(
      '/affectations',
      data: {
        'utilisateurId': utilisateurId,
        'chantierId': chantierId,
        if (dateAffectation != null)
          'dateAffectation': dateAffectation.toIso8601String().substring(0, 10),
      },
    );
    return Affectation.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/affectations/$id');
  }
}

/// /api/utilisateurs (admin view)
class UtilisateurAdminService {
  final _client = ApiClient();

  Future<List<Utilisateur>> getAll() async {
    final res = await _client.dio.get('/utilisateurs');
    return _asList(res.data, Utilisateur.fromJson);
  }

  Future<Utilisateur> create({
    required String nom,
    required String email,
    String? telephone,
    required String motDePasse,
  }) async {
    final res = await _client.dio.post(
      '/utilisateurs',
      data: {
        'nom': nom,
        'email': email,
        if (telephone != null) 'telephone': telephone,
        'motDePasse': motDePasse,
        'role': 'CHEF_CHANTIER',
      },
    );
    return Utilisateur.fromJson(res.data);
  }

  Future<Utilisateur> update({
    required int id,
    required String nom,
    required String email,
    String? telephone,
    String? motDePasse,
  }) async {
    final data = <String, dynamic>{
      'nom': nom,
      'email': email,
      if (telephone != null) 'telephone': telephone,
      if (motDePasse != null && motDePasse.isNotEmpty) 'motDePasse': motDePasse,
      'role': 'CHEF_CHANTIER',
    };
    final res = await _client.dio.put('/utilisateurs/$id', data: data);
    return Utilisateur.fromJson(res.data);
  }

  Future<void> delete(int id) async {
    await _client.dio.delete('/utilisateurs/$id');
  }
}
