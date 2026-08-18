# 🏗️ ChantierPro — Application de gestion et suivi de chantiers

Application mobile complète : **Flutter** (frontend) + **Spring Boot** (backend) + **MySQL**.
Frontend et backend sont entièrement liés : toutes les données affichées proviennent de l'API (aucune donnée statique).

---

## 📁 Structure du projet

```
ChantierPro/
├── backend/     → API REST Spring Boot 3.5 (JWT, MySQL, upload photos, Swagger)
├── frontend/    → Application Flutter (Android / iOS / Web)
└── README.md
```

---

## ✅ Fonctionnalités opérationnelles

| Fonctionnalité | Détail |
|---|---|
| **Authentification** | Inscription + connexion réelles via `/api/auth` (JWT). Session persistée : on reste connecté après redémarrage. Déconnexion depuis le profil. |
| **Dashboard temps réel** | KPIs calculés depuis la base : chantiers actifs, tâches en retard, budget total + % consommé (dépenses réelles), rapports du mois. Tirer vers le bas pour rafraîchir. |
| **Alerte retard** | La bannière rouge s'affiche automatiquement dès qu'au moins un chantier a le statut `retard` (avec le nombre exact). Elle disparaît s'il n'y en a aucun. |
| **Chantiers** | Liste depuis l'API, recherche, filtres par statut, création via le formulaire (POST réel). L'avancement est calculé à partir des tâches terminées. |
| **Détail chantier** | Onglets Infos / Budget / **Tâches (API)** / **Rapports (API)** / **Galerie (API)** filtrés par chantier. |
| **Tâches** | Liste réelle, filtres par statut, ajout avec sélection du chantier, date limite, statut. |
| **Rapports** | Liste réelle, ajout avec chantier + date + type + contenu + **photos jointes**. |
| **Upload photo** | Depuis la galerie ou l'appareil photo → `POST /api/photos/upload` (multipart, max 5 Mo). Les photos s'affichent sur les rapports et dans la galerie du chantier. |
| **Profil** | Données réelles via `/api/utilisateurs/me` (nom, email, téléphone, rôle) + statistiques réelles (nb chantiers / tâches / rapports). |
| **Internationalisation** | FR / EN sur toute l'application (dashboard, listes, formulaires, alertes, messages). Changement de langue dans Profil → Paramètres. |
| **Icône de l'app** | Votre logo (casque + grue) est installé pour Android (toutes densités), iOS et Web. |

---

## 🚀 Démarrage

### 1. Base de données MySQL

Le backend attend MySQL sur le **port 3307** :

```sql
CREATE DATABASE construction_db;
```

Identifiants configurés dans `backend/src/main/resources/application.properties` :
```properties
spring.datasource.url=jdbc:mysql://localhost:3307/construction_db
spring.datasource.username=root
spring.datasource.password=root123
```
> Adaptez le port / mot de passe à votre installation si nécessaire.
> Les tables sont créées automatiquement (`ddl-auto=update`).

### 2. Backend Spring Boot

```bash
cd backend
./mvnw spring-boot:run        # Windows : mvnw.cmd spring-boot:run
```

- API disponible sur `http://localhost:8080`
- Documentation Swagger : `http://localhost:8080/swagger-ui/index.html`

### 3. Frontend Flutter

```bash
cd frontend
flutter pub get
flutter run
```

#### ⚠️ URL du backend selon votre appareil

| Où tourne l'app | Commande |
|---|---|
| **Émulateur Android** | `flutter run` (défaut : `http://10.0.2.2:8080`) |
| **Simulateur iOS** | `flutter run --dart-define=API_BASE_URL=http://localhost:8080` |
| **Téléphone physique** | `flutter run --dart-define=API_BASE_URL=http://IP_DE_VOTRE_PC:8080` |

> Pour un téléphone physique : le téléphone et le PC doivent être sur le **même réseau Wi-Fi**.
> Trouvez l'IP de votre PC avec `ipconfig` (Windows) ou `ip a` (Linux).
> Vérifiez que le pare-feu autorise le port 8080.

### 4. Premier compte

Aucun compte n'existe au départ : utilisez l'écran **S'inscrire** de l'application
(rôle *Administrateur* ou *Chef de chantier*). Le mot de passe doit faire **au moins 8 caractères**.

Ensuite : créez un chantier → ajoutez des tâches → rédigez des rapports avec photos.
Le dashboard se met à jour avec les vraies données.

---

## 🔧 Architecture frontend (couche API ajoutée)

```
frontend/lib/core/
├── api/
│   ├── api_config.dart       → URL du backend (surchargeable par --dart-define)
│   ├── api_client.dart       → Client Dio + injection auto du token JWT + gestion d'erreurs
│   ├── auth_session.dart     → Session persistée (token + utilisateur)
│   ├── auth_service.dart     → login / register / me / logout
│   └── data_services.dart    → ChantierService, TacheService, RapportService, PhotoService, DepenseService
├── models/                   → Chantier, Tache, Rapport, Photo, Utilisateur, Depense (miroirs des DTOs)
└── utils/chantier_mapper.dart → Calcul avancement (tâches) & budget consommé (dépenses)
```

Le routeur (`go_router`) inclut une **garde d'authentification** : sans token valide,
redirection automatique vers la connexion ; un token expiré (401) déconnecte proprement.

## 📝 Choix techniques à connaître

- **Type de rapport** : le backend ne stocke que le contenu ; le type (journalier, incident…)
  est encodé en préfixe `[type]` dans le contenu et ré-affiché proprement dans l'app.
- **Avancement d'un chantier** = tâches terminées / tâches totales (calcul côté app).
- **Budget consommé** = somme des dépenses (`/api/depenses`) du chantier.
- **Photos** : rattachées aux rapports (modèle backend). Dans la galerie d'un chantier,
  une nouvelle photo est jointe au rapport le plus récent ; s'il n'y a aucun rapport,
  l'app demande d'en créer un d'abord.
- **Modifs backend minimes** : ajout de `CorsConfig` (Flutter Web/dev) et ouverture de la
  création/modification de chantier au rôle `CHEF_CHANTIER` (nécessaire pour que le bouton
  « Nouveau chantier » fonctionne pour tous les comptes). Tout le reste est inchangé.
- **Android** : `INTERNET` + `usesCleartextTraffic=true` ajoutés (l'API est en HTTP local).
- **iOS** : permissions caméra/galerie + exception ATS ajoutées dans `Info.plist`.

---

## 🧪 Vérification rapide de la liaison

1. Lancez le backend, puis l'app.
2. Inscrivez-vous → un utilisateur apparaît dans la table `utilisateur` de MySQL.
3. Créez un chantier avec le statut par défaut, puis passez-le en `retard` (via un
   deuxième chantier créé, ou Swagger `PUT /api/chantiers/{id}` avec `"statut": "retard"`) :
   la **bannière d'alerte rouge** apparaît sur le dashboard.
4. Ajoutez un rapport avec une photo → la photo est stockée dans `backend/uploads/photos/`
   et visible dans l'app.
