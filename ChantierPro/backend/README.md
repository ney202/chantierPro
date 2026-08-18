# Smart Chantier — API Backend

API REST de gestion intelligente des chantiers, développée avec Spring Boot 3.  
Authentification JWT, contrôle d'accès par rôle, pagination, tri, recherche et upload de photos.

---

## Table des matières

1. [Aperçu du projet](#aperçu-du-projet)
2. [Technologies utilisées](#technologies-utilisées)
3. [Fonctionnalités](#fonctionnalités)
4. [Rôles et permissions](#rôles-et-permissions)
5. [Prérequis](#prérequis)
6. [Configuration MySQL](#configuration-mysql)
7. [Lancer le projet](#lancer-le-projet)
8. [Documentation Swagger](#documentation-swagger)
9. [Authentification](#authentification)
10. [Endpoints principaux](#endpoints-principaux)
11. [Pagination et tri](#pagination-et-tri)
12. [Recherche et filtrage](#recherche-et-filtrage)
13. [Upload de photo](#upload-de-photo)
14. [Accès aux images uploadées](#accès-aux-images-uploadées)
15. [Notes pour le frontend Flutter](#notes-pour-le-frontend-flutter)

---

## Aperçu du projet

**Smart Chantier** est une API backend destinée à la gestion complète de chantiers de construction.  
Elle permet de gérer les utilisateurs, les chantiers, les rapports, les tâches, les dépenses, les photos, les affectations et les alertes.

- Port par défaut : **8080**
- Base URL : `http://localhost:8080`
- Toutes les routes (sauf `/api/auth/**` et `/uploads/**`) nécessitent un **token JWT**.

---

## Technologies utilisées

| Technologie | Version |
|---|---|
| Java | 17 |
| Spring Boot | 3.5.x |
| Spring Security | 6.x |
| Spring Data JPA | 3.x |
| Hibernate | 6.x |
| MySQL | 8.x |
| JWT (jjwt) | 0.12.6 |
| Lombok | Latest |
| springdoc-openapi (Swagger) | 2.8.3 |
| Maven | 3.x (wrapper inclus) |

---

## Fonctionnalités

- **Authentification JWT** — inscription, connexion, token Bearer
- **Contrôle d'accès par rôle** — `ADMIN` et `CHEF_CHANTIER`
- **CRUD complet** sur 8 ressources : Utilisateur, Chantier, Rapport, Tâche, Dépense, Photo, Affectation, Alerte
- **Upload de photos** — stockage local, validation du type et de la taille
- **Pagination** optionnelle sur tous les endpoints `GET /api/{ressource}`
- **Tri** optionnel combiné avec la pagination
- **Recherche/filtrage** sur tous les endpoints `GET /api/{ressource}/search`
- **Swagger UI** intégré avec support du token Bearer
- **Gestion des erreurs** — réponses JSON propres sans stack trace

---

## Rôles et permissions

### ADMIN
Accès total à toutes les ressources.

| Action | Accès |
|---|---|
| Gérer les utilisateurs (CRUD) | ✅ |
| Gérer les chantiers (CRUD) | ✅ |
| Gérer les rapports, tâches, dépenses, photos, affectations, alertes | ✅ |
| Supprimer toutes les ressources | ✅ |
| Consulter son propre profil (`/me`) | ✅ |

### CHEF_CHANTIER
Accès en lecture/création/modification, sans droits de suppression ni gestion des utilisateurs.

| Action | Accès |
|---|---|
| Consulter son propre profil (`GET /api/utilisateurs/me`) | ✅ |
| Créer/modifier des utilisateurs | ❌ |
| Consulter les chantiers | ✅ |
| Créer ou modifier des chantiers | ❌ |
| Consulter, créer et modifier : rapports, tâches, dépenses, photos, alertes | ✅ |
| Supprimer des ressources | ❌ |
| Gérer les affectations | ❌ (lecture seule) |

---

## Prérequis

- **JDK 17** ou supérieur
- **MySQL 8** démarré et accessible
- **Maven** (ou utiliser le wrapper `./mvnw` inclus)
- Optionnel : Postman, IntelliJ IDEA, Flutter SDK

---

## Configuration MySQL

Créer la base de données avant de lancer l'application :

```sql
CREATE DATABASE construction_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Le fichier `src/main/resources/application.properties` contient la configuration par défaut :

```properties
spring.datasource.url=jdbc:mysql://localhost:3307/construction_db
spring.datasource.username=root
spring.datasource.password=root123

spring.jpa.hibernate.ddl-auto=update
```

> Modifier `spring.datasource.url`, `username` et `password` selon votre environnement local.  
> Le port **3307** est utilisé par défaut — remplacer par **3306** si besoin.

---

## Lancer le projet

### Via le wrapper Maven (recommandé)

```bash
# Windows
.\mvnw.cmd spring-boot:run

# Linux / macOS
./mvnw spring-boot:run
```

### Via Maven installé

```bash
mvn spring-boot:run
```

### Via le JAR compilé

```bash
mvn package -DskipTests
java -jar target/chantier-management-0.0.1-SNAPSHOT.jar
```

Une fois démarré, l'API est accessible sur : `http://localhost:8080`

---

## Documentation Swagger

| Ressource | URL |
|---|---|
| Swagger UI | `http://localhost:8080/swagger-ui/index.html` |
| OpenAPI JSON | `http://localhost:8080/v3/api-docs` |

### Utiliser le token dans Swagger UI

1. Ouvrir `http://localhost:8080/swagger-ui/index.html`
2. Appeler `POST /api/auth/login` pour obtenir un token
3. Cliquer sur le bouton **Authorize** (icône cadenas en haut à droite)
4. Saisir le token *(sans le préfixe `Bearer `)*
5. Cliquer sur **Authorize** — toutes les requêtes suivantes incluront automatiquement le header

---

## Authentification

### Inscription

```http
POST /api/auth/register
Content-Type: application/json

{
  "nom": "Ahmed Benali",
  "email": "ahmed@example.com",
  "telephone": "0612345678",
  "role": "CHEF_CHANTIER",
  "motDePasse": "motdepasse123"
}
```

**Valeurs acceptées pour `role` :** `ADMIN`, `CHEF_CHANTIER`

**Réponse (200) :**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

---

### Connexion

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "ahmed@example.com",
  "motDePasse": "motdepasse123"
}
```

**Réponse (200) :**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

---

### Utiliser le token Bearer

Ajouter le header suivant à toutes les requêtes protégées :

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

---

## Endpoints principaux

### Utilisateurs `/api/utilisateurs`

| Méthode | URL | Rôle requis | Description |
|---|---|---|---|
| GET | `/api/utilisateurs/me` | ADMIN, CHEF_CHANTIER | Profil connecté |
| GET | `/api/utilisateurs` | ADMIN | Liste tous les utilisateurs |
| GET | `/api/utilisateurs/{id}` | ADMIN | Détail d'un utilisateur |
| POST | `/api/utilisateurs` | ADMIN | Créer un utilisateur |
| PUT | `/api/utilisateurs/{id}` | ADMIN | Modifier un utilisateur |
| DELETE | `/api/utilisateurs/{id}` | ADMIN | Supprimer un utilisateur |
| GET | `/api/utilisateurs/search` | ADMIN | Recherche par nom/email |

---

### Chantiers `/api/chantiers`

| Méthode | URL | Rôle requis | Description |
|---|---|---|---|
| GET | `/api/chantiers` | ADMIN, CHEF_CHANTIER | Liste tous les chantiers |
| GET | `/api/chantiers/{id}` | ADMIN, CHEF_CHANTIER | Détail d'un chantier |
| POST | `/api/chantiers` | ADMIN | Créer un chantier |
| PUT | `/api/chantiers/{id}` | ADMIN | Modifier un chantier |
| DELETE | `/api/chantiers/{id}` | ADMIN | Supprimer un chantier |
| GET | `/api/chantiers/search` | ADMIN, CHEF_CHANTIER | Recherche par nom/statut |

**Corps de création :**
```json
{
  "nom": "Chantier Route N12",
  "localisation": "Casablanca",
  "dateDebut": "2025-01-15",
  "dateFinPrevue": "2025-12-31",
  "budget": 1500000.00,
  "statut": "EN_COURS",
  "chefId": 2
}
```

---

### Rapports `/api/rapports`

| Méthode | URL | Rôle requis | Description |
|---|---|---|---|
| GET | `/api/rapports` | ADMIN, CHEF_CHANTIER | Liste tous les rapports |
| GET | `/api/rapports/{id}` | ADMIN, CHEF_CHANTIER | Détail d'un rapport |
| POST | `/api/rapports` | ADMIN, CHEF_CHANTIER | Créer un rapport |
| PUT | `/api/rapports/{id}` | ADMIN, CHEF_CHANTIER | Modifier un rapport |
| DELETE | `/api/rapports/{id}` | ADMIN | Supprimer un rapport |
| GET | `/api/rapports/search` | ADMIN, CHEF_CHANTIER | Recherche par chantier/auteur |

---

### Tâches `/api/taches`

| Méthode | URL | Rôle requis | Description |
|---|---|---|---|
| GET | `/api/taches` | ADMIN, CHEF_CHANTIER | Liste toutes les tâches |
| GET | `/api/taches/{id}` | ADMIN, CHEF_CHANTIER | Détail d'une tâche |
| POST | `/api/taches` | ADMIN, CHEF_CHANTIER | Créer une tâche |
| PUT | `/api/taches/{id}` | ADMIN, CHEF_CHANTIER | Modifier une tâche |
| DELETE | `/api/taches/{id}` | ADMIN | Supprimer une tâche |
| GET | `/api/taches/search` | ADMIN, CHEF_CHANTIER | Recherche par statut/chantier |

---

### Dépenses `/api/depenses`

| Méthode | URL | Rôle requis | Description |
|---|---|---|---|
| GET | `/api/depenses` | ADMIN, CHEF_CHANTIER | Liste toutes les dépenses |
| GET | `/api/depenses/{id}` | ADMIN, CHEF_CHANTIER | Détail d'une dépense |
| POST | `/api/depenses` | ADMIN, CHEF_CHANTIER | Créer une dépense |
| PUT | `/api/depenses/{id}` | ADMIN, CHEF_CHANTIER | Modifier une dépense |
| DELETE | `/api/depenses/{id}` | ADMIN | Supprimer une dépense |
| GET | `/api/depenses/search` | ADMIN, CHEF_CHANTIER | Recherche par chantier |

---

### Photos `/api/photos`

| Méthode | URL | Rôle requis | Description |
|---|---|---|---|
| GET | `/api/photos` | ADMIN, CHEF_CHANTIER | Liste toutes les photos |
| GET | `/api/photos/{id}` | ADMIN, CHEF_CHANTIER | Détail d'une photo |
| POST | `/api/photos/upload` | ADMIN, CHEF_CHANTIER | **Upload d'un fichier image** |
| POST | `/api/photos` | ADMIN, CHEF_CHANTIER | Créer une entrée photo (URL manuelle) |
| PUT | `/api/photos/{id}` | ADMIN, CHEF_CHANTIER | Modifier une photo |
| DELETE | `/api/photos/{id}` | ADMIN | Supprimer une photo |
| GET | `/api/photos/search` | ADMIN, CHEF_CHANTIER | Recherche par rapport |

---

### Affectations `/api/affectations`

| Méthode | URL | Rôle requis | Description |
|---|---|---|---|
| GET | `/api/affectations` | ADMIN, CHEF_CHANTIER | Liste toutes les affectations |
| GET | `/api/affectations/{id}` | ADMIN, CHEF_CHANTIER | Détail d'une affectation |
| POST | `/api/affectations` | ADMIN | Créer une affectation |
| PUT | `/api/affectations/{id}` | ADMIN | Modifier une affectation |
| DELETE | `/api/affectations/{id}` | ADMIN | Supprimer une affectation |
| GET | `/api/affectations/search` | ADMIN, CHEF_CHANTIER | Recherche par utilisateur/chantier |

---

### Alertes `/api/alertes`

| Méthode | URL | Rôle requis | Description |
|---|---|---|---|
| GET | `/api/alertes` | ADMIN, CHEF_CHANTIER | Liste toutes les alertes |
| GET | `/api/alertes/{id}` | ADMIN, CHEF_CHANTIER | Détail d'une alerte |
| POST | `/api/alertes` | ADMIN, CHEF_CHANTIER | Créer une alerte |
| PUT | `/api/alertes/{id}` | ADMIN, CHEF_CHANTIER | Modifier une alerte |
| DELETE | `/api/alertes/{id}` | ADMIN | Supprimer une alerte |
| GET | `/api/alertes/search` | ADMIN, CHEF_CHANTIER | Recherche par statut/chantier |

---

## Pagination et tri

La pagination est **optionnelle**. Sans paramètres, l'endpoint retourne la liste complète (`List`).  
Avec `page` et `size`, il retourne un objet `Page` Spring Data.

### Paramètres disponibles

| Paramètre | Type | Défaut | Description |
|---|---|---|---|
| `page` | Integer | — | Numéro de page (commence à 0) |
| `size` | Integer | — | Nombre d'éléments par page |
| `sortBy` | String | `id` | Champ de tri (nom du champ entité) |
| `direction` | String | `asc` | Sens du tri : `asc` ou `desc` |

> `sortBy` et `direction` ne s'appliquent que si `page` et `size` sont fournis.

### Exemples

```
# Liste complète (comportement original)
GET /api/chantiers

# Page 0, 10 éléments, tri par défaut (id asc)
GET /api/chantiers?page=0&size=10

# Page 1, 5 éléments, triés par nom
GET /api/chantiers?page=1&size=5&sortBy=nom&direction=asc

# Tâches : page 0, triées par dateDebut décroissant
GET /api/taches?page=0&size=10&sortBy=dateDebut&direction=desc

# Photos triées par date d'upload
GET /api/photos?page=0&size=20&sortBy=dateUpload&direction=desc

# Dépenses triées par montant décroissant
GET /api/depenses?page=0&size=10&sortBy=montant&direction=desc
```

### Structure de la réponse paginée

```json
{
  "content": [
    { "id": 1, "nom": "Chantier Route N12", "statut": "EN_COURS", "..." : "..." }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 10,
    "sort": { "sorted": true, "direction": "DESC" }
  },
  "totalElements": 42,
  "totalPages": 5,
  "first": true,
  "last": false,
  "numberOfElements": 10,
  "empty": false
}
```

### Champs de tri valides par ressource

| Ressource | Champs disponibles |
|---|---|
| Utilisateur | `id`, `nom`, `email` |
| Chantier | `id`, `nom`, `dateDebut`, `dateFinPrevue`, `budget`, `statut` |
| Rapport | `id`, `dateRapport` |
| Tâche | `id`, `titre`, `dateDebut`, `dateFin`, `statut` |
| Dépense | `id`, `montant`, `dateDepense` |
| Photo | `id`, `dateUpload` |
| Affectation | `id`, `dateAffectation` |
| Alerte | `id`, `dateCreation`, `statut` |

---

## Recherche et filtrage

Chaque ressource dispose d'un endpoint `/search` avec des filtres optionnels.  
Les paramètres non fournis sont ignorés (retourne tout sans ce filtre).

### Exemples par ressource

```
# Chantiers : par nom (contient, insensible à la casse) et/ou statut (exact)
GET /api/chantiers/search?nom=route
GET /api/chantiers/search?statut=EN_COURS
GET /api/chantiers/search?nom=route&statut=EN_COURS

# Tâches : par statut et/ou chantier
GET /api/taches/search?statut=EN_COURS
GET /api/taches/search?chantierId=3
GET /api/taches/search?statut=TERMINE&chantierId=3

# Rapports : par chantier et/ou auteur
GET /api/rapports/search?chantierId=1
GET /api/rapports/search?auteurId=2
GET /api/rapports/search?chantierId=1&auteurId=2

# Dépenses : par chantier
GET /api/depenses/search?chantierId=1

# Photos : par rapport
GET /api/photos/search?rapportId=5

# Affectations : par utilisateur et/ou chantier
GET /api/affectations/search?utilisateurId=4
GET /api/affectations/search?chantierId=2
GET /api/affectations/search?utilisateurId=4&chantierId=2

# Alertes : par statut et/ou chantier
GET /api/alertes/search?statut=ACTIVE
GET /api/alertes/search?chantierId=1&statut=RESOLUE

# Utilisateurs (ADMIN uniquement) : par nom et/ou email (contient)
GET /api/utilisateurs/search?nom=ali
GET /api/utilisateurs/search?email=@gmail.com
GET /api/utilisateurs/search?nom=ali&email=ali@
```

La recherche retourne toujours une `List` (pas de pagination sur `/search`).

---

## Upload de photo

### Règles

| Règle | Valeur |
|---|---|
| Endpoint | `POST /api/photos/upload` |
| Type de contenu | `multipart/form-data` |
| Champ fichier | `file` |
| Champ rapport | `rapportId` (Long) |
| Types acceptés | `image/jpeg`, `image/jpg`, `image/png`, `image/webp` |
| Taille maximale | **5 MB** |
| Stockage | `uploads/photos/` (relatif au répertoire de lancement) |
| URL générée | `/uploads/photos/{uuid}.jpg` |

### Exemple avec Postman

```
POST http://localhost:8080/api/photos/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

Body (form-data) :
  file      → [sélectionner un fichier image]
  rapportId → 1
```

### Réponse (201 Created)

```json
{
  "id": 7,
  "urlPhoto": "/uploads/photos/550e8400-e29b-41d4-a716-446655440000.jpg",
  "dateUpload": "2025-07-09",
  "rapportId": 1
}
```

### Erreurs possibles

```json
{ "status": 400, "error": "Bad Request", "message": "File must not be empty." }
{ "status": 400, "error": "Bad Request", "message": "Unsupported file type: application/pdf. Allowed types: image/jpeg, image/jpg, image/png, image/webp." }
{ "status": 400, "error": "Bad Request", "message": "File size exceeds the maximum allowed size of 5MB." }
{ "status": 413, "error": "File Too Large", "message": "File size exceeds the maximum allowed size of 5MB." }
```

---

## Accès aux images uploadées

Les images uploadées sont servies comme ressources statiques — **aucun token JWT requis**.

```
GET http://localhost:8080/uploads/photos/550e8400-e29b-41d4-a716-446655440000.jpg
```

Le champ `urlPhoto` retourné par l'API est le chemin relatif.  
Pour construire l'URL complète depuis Flutter :

```dart
final baseUrl = 'http://localhost:8080';
final imageUrl = '$baseUrl${photo.urlPhoto}';
// → http://localhost:8080/uploads/photos/550e8400-....jpg
```

---

## Notes pour le frontend Flutter

### Configuration de base

```dart
const String baseUrl = 'http://10.0.2.2:8080'; // émulateur Android
// ou
const String baseUrl = 'http://192.168.x.x:8080'; // appareil physique (IP locale)
```

> Sur émulateur Android, `localhost` ne pointe pas vers la machine hôte — utiliser `10.0.2.2`.

### Authentification — stocker et envoyer le token

```dart
// Connexion
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'email': 'ahmed@example.com', 'motDePasse': 'motdepasse123'}),
);
final token = jsonDecode(response.body)['token'];

// Requête protégée
final data = await http.get(
  Uri.parse('$baseUrl/api/chantiers'),
  headers: {'Authorization': 'Bearer $token'},
);
```

### Upload de photo

```dart
Future<Map<String, dynamic>> uploadPhoto(
    File imageFile, int rapportId, String token) async {
  final uri = Uri.parse('$baseUrl/api/photos/upload');
  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(await http.MultipartFile.fromPath('file', imageFile.path))
    ..fields['rapportId'] = rapportId.toString();

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  return jsonDecode(response.body) as Map<String, dynamic>;
}
```

### Requête paginée avec tri

```dart
Future<Map<String, dynamic>> getChantiersPaged({
  required int page,
  required int size,
  String sortBy = 'id',
  String direction = 'asc',
  required String token,
}) async {
  final uri = Uri.parse('$baseUrl/api/chantiers').replace(queryParameters: {
    'page': '$page',
    'size': '$size',
    'sortBy': sortBy,
    'direction': direction,
  });
  final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
  return jsonDecode(response.body) as Map<String, dynamic>;
}
```

### Modèle de réponse paginée

```dart
class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final bool last;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.last,
  });

  factory PageResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return PageResponse(
      content: (json['content'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      pageNumber: (json['pageable'] as Map)['pageNumber'] as int,
      last: json['last'] as bool,
    );
  }
}
```

### Recherche

```dart
Future<List<dynamic>> searchChantiers(
    {String? nom, String? statut, required String token}) async {
  final params = <String, String>{};
  if (nom != null && nom.isNotEmpty) params['nom'] = nom;
  if (statut != null && statut.isNotEmpty) params['statut'] = statut;

  final uri = Uri.parse('$baseUrl/api/chantiers/search')
      .replace(queryParameters: params.isEmpty ? null : params);
  final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
  return jsonDecode(response.body) as List<dynamic>;
}
```

### Gestion des erreurs

Toutes les erreurs retournent du JSON avec la structure suivante :

```json
{
  "status": 404,
  "error": "Not Found",
  "message": "Chantier non trouvé avec l'id : 99",
  "timestamp": "2025-07-09T10:30:00"
}
```

```dart
if (response.statusCode != 200 && response.statusCode != 201) {
  final error = jsonDecode(response.body);
  throw Exception(error['message'] ?? 'Erreur inconnue');
}
```

---

## Structure du projet

```
src/main/java/com/medplatform/chantiermanagement/
├── config/
│   ├── ApplicationConfig.java       # Beans de sécurité (PasswordEncoder, AuthProvider)
│   ├── OpenApiConfig.java           # Configuration Swagger + JWT Bearer
│   ├── SecurityConfig.java          # Filtres et règles d'autorisation
│   └── WebMvcConfig.java            # Ressources statiques (uploads)
├── controller/                      # Couche REST (8 contrôleurs)
├── dto/                             # Objets de transfert (Request / Response)
├── entity/                          # Entités JPA
├── enums/
│   └── Role.java                    # ADMIN, CHEF_CHANTIER
├── exception/                       # Exceptions métier + GlobalExceptionHandler
├── filter/
│   └── JwtAuthenticationFilter.java # Validation du token à chaque requête
├── repository/                      # Interfaces Spring Data JPA + @Query de recherche
├── security/                        # EntryPoint et AccessDeniedHandler personnalisés
└── service/                         # Logique métier (8 services)

src/main/resources/
├── application.properties           # Configuration datasource, JWT, multipart
uploads/photos/                      # Images uploadées (créé automatiquement)
```

---

*Projet développé avec Spring Boot 3 — Smart Chantier Backend API*
