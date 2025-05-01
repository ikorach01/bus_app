# 3. Analyse et Modélisation UML de l'Application BusApp

## 3.1 Introduction

Ce chapitre présente une analyse détaillée de l'application BusApp à travers les diagrammes UML (Unified Modeling Language), offrant une vue d'ensemble de son architecture, de ses fonctionnalités et de ses interactions.

## 3.2 Présentation de la méthode UML

### 3.2.1 Qu'est-ce que l'UML ?

UML (Unified Modeling Language) est un langage de modélisation graphique standardisé utilisé dans le développement de logiciels pour visualiser, spécifier, construire et documenter les artefacts d'un système logiciel.

### 3.2.2 Historique et motivation de la création de l'UML

- Créé en 1997 par Grady Booch, James Rumbaugh et Ivar Jacobson
- Objectif : Standardiser les méthodes de conception de systèmes orientés objet
- Réponse au besoin de communication claire entre développeurs et parties prenantes

### 3.2.3 Principaux objectifs et avantages de l'UML

- Fournir un langage de modélisation visuel et standardisé
- Améliorer la communication entre les équipes de développement
- Faciliter la conception et la documentation des systèmes complexes
- Permettre une vue abstraite et concrète du système

## 3.3 Recueil des besoins de l'application BusApp

L'application BusApp vise à fournir :
- Suivi en temps réel des bus
- Gestion des trajets pour les conducteurs
- Inscription et authentification des utilisateurs
- Sélection et recherche de stations
- Gestion des informations de véhicules et de conducteurs

## 3.4 Diagramme de cas d'utilisation

### 3.4.1 Identification des acteurs

1. **Conducteur**
   - S'inscrire et s'authentifier
   - Gérer son profil
   - Démarrer et terminer des trajets
   - Visualiser les informations de trajet

2. **Passager** (fonctionnalités futures)
   - Rechercher des trajets
   - Suivre les bus en temps réel
   - Consulter les horaires

3. **Administrateur**
   - Gérer les utilisateurs
   - Configurer le système
   - Générer des rapports

### 3.4.2 Diagramme global des cas d'utilisation

```plantuml
left to right direction
actor Conducteur
actor Administrateur

rectangle "BusApp" {
    Conducteur --> (S'authentifier)
    Conducteur --> (Gérer profil)
    Conducteur --> (Démarrer trajet)
    Conducteur --> (Terminer trajet)
    Conducteur --> (Suivre position du bus)
    
    Administrateur --> (Gérer utilisateurs)
    Administrateur --> (Configurer système)
}
```

## 3.5 Diagramme de classes

### 3.5.1 Présentation des entités principales

1. **Conducteur**
   - Identifiant
   - Nom et prénom
   - Informations de permis
   - Informations de véhicule

2. **Bus**
   - Identifiant
   - Nom
   - Plaque d'immatriculation
   - Photo

3. **Trajet**
   - Station de départ
   - Station d'arrivée
   - Heure de début
   - Heure de fin

4. **Station**
   - Identifiant
   - Nom
   - Coordonnées géographiques
   - Municipalité

### 3.5.2 Diagramme de classes de l'application

```plantuml
class Conducteur {
  - id: UUID
  - nom: String
  - prenom: String
  - dateNaissance: Date
  + enregistrerInformations()
  + mettreAJourProfil()
}

class Bus {
  - id: UUID
  - nom: String
  - plaqueImmatriculation: String
  - photo: Byte[]
  + obtenirInformations()
}

class Trajet {
  - id: UUID
  - conducteurId: UUID
  - busId: UUID
  - stationDepart: Station
  - stationArrivee: Station
  - heureDebut: DateTime
  - heureFin: DateTime
  + demarrerTrajet()
  + terminerTrajet()
}

class Station {
  - id: UUID
  - nom: String
  - latitude: Float
  - longitude: Float
  - municipalite: String
  + obtenirCoordonnees()
}

class PositionBus {
  - busId: UUID
  - latitude: Float
  - longitude: Float
  - vitesse: Float
  - horodatage: DateTime
  + mettreAJourPosition()
}

Conducteur "1" -- "0..*" Trajet
Bus "1" -- "0..*" Trajet
Trajet "1" -- "2" Station
Bus "1" -- "0..*" PositionBus
```

## 3.6 Diagrammes de séquence

### 3.6.1 Scénario de recherche et visualisation d'un trajet

```plantuml
actor Conducteur
participant "Interface Utilisateur" as UI
participant "Service de Recherche" as Recherche
participant "Base de Données" as DB

Conducteur -> UI: Sélectionner stations
UI -> Recherche: Rechercher trajets disponibles
Recherche -> DB: Requête de recherche
DB --> Recherche: Résultats des trajets
Recherche --> UI: Afficher trajets
UI --> Conducteur: Présenter options de trajet
```

### 3.6.2 Scénario de suivi en temps réel d'un bus

```plantuml
actor Conducteur
participant "Interface Utilisateur" as UI
participant "Service de Localisation" as Localisation
participant "Base de Données" as DB

Conducteur -> UI: Démarrer trajet
UI -> Localisation: Initialiser suivi
loop Mise à jour périodique
    Localisation -> DB: Enregistrer position
    Localisation -> UI: Mettre à jour carte
end
```

## 3.7 Architecture générale de l'application

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL)
- **Authentification**: Supabase Auth
- **Gestion d'état**: Provider
- **Stockage**: Base de données relationnelle

Architecture modulaire avec séparation des préoccupations :
- Couche présentation (UI)
- Couche métier (Providers)
- Couche données (Services Supabase)

## 3.8 Conclusion du chapitre

Ce chapitre a présenté une analyse UML détaillée de l'application BusApp, mettant en lumière sa structure, ses acteurs, ses cas d'utilisation et son architecture. Les diagrammes UML offrent une vue claire et structurée du système, facilitant sa compréhension et son développement.

Les prochaines étapes incluront :
- Raffinement des modèles UML
- Implémentation des fonctionnalités
- Tests et validation
