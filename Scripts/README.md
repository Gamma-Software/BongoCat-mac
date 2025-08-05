# BongoCat Scripts

Ce dossier contient tous les scripts de build, packaging et distribution pour BongoCat.

## Scripts Principaux

### 🔨 `build.sh` - Script de Build Principal
Script tout-en-un pour build, test, run et installation locale.

**Usage:**
```bash
./Scripts/build.sh [OPTIONS]
```

**Options:**
- `--debug, -d` : Build en mode debug (par défaut)
- `--release, -r` : Build en mode release
- `--clean, -c` : Nettoyer les artefacts de build avant de builder
- `--test, -t` : Lancer les tests après le build
- `--run, -u` : Lancer l'app après le build
- `--install, -i` : Installer l'app localement après le build
- `--test-run, -tr` : Build, test et run
- `--test-install, -ti` : Build, test et installation locale
- `--run-install, -ri` : Build, run et installation locale
- `--all, -a` : Build, test, run et installation locale

**Exemples:**
```bash
./Scripts/build.sh --debug --test
./Scripts/build.sh --release --run
./Scripts/build.sh --all
```

### 🔍 `verify.sh` - Script de Vérification
Vérifie l'environnement, les signatures et les différentes étapes.

**Usage:**
```bash
./Scripts/verify.sh [OPTIONS]
```

**Options:**
- `--environment, -e` : Vérifier la configuration de l'environnement de développement
- `--signature, -s` : Vérifier la signature de l'app et les certificats
- `--notarization, -n` : Vérifier le statut de notarization de l'app
- `--build, -b` : Vérifier les artefacts de build et les dépendances
- `--all, -a` : Lancer toutes les vérifications

**Exemples:**
```bash
./Scripts/verify.sh --environment
./Scripts/verify.sh --signature
./Scripts/verify.sh --all
```

### 🔐 `sign.sh` - Script de Signature
Signature de l'app, du PKG et notarization.

**Usage:**
```bash
./Scripts/sign.sh [OPTIONS]
```

**Options:**
- `--app, -a` : Signer le bundle de l'app
- `--pkg, -p` : Signer l'installateur PKG
- `--notarize, -n` : Notarizer l'app
- `--all, -A` : Signer app, PKG et notarizer
- `--adhoc, -d` : Forcer la signature ad-hoc (pas de certificat)
- `--certificate, -c` : Forcer la signature avec certificat
- `--auto, -u` : Auto-détection du certificat (par défaut)
- `--force, -f` : Forcer la re-signature même si déjà signé

**Exemples:**
```bash
./Scripts/sign.sh --app
./Scripts/sign.sh --app --notarize
./Scripts/sign.sh --all
```

### 📦 `package.sh` - Script de Packaging
Génération du DMG et création du PKG.

**Usage:**
```bash
./Scripts/package.sh [OPTIONS]
```

**Options:**
- `--dmg, -d` : Créer seulement le fichier DMG
- `--pkg, -p` : Créer seulement le fichier PKG
- `--debug, -D` : Packager le build debug
- `--app-store, -a` : Packager pour la distribution App Store

**Exemples:**
```bash
./Scripts/package.sh
./Scripts/package.sh --dmg
./Scripts/package.sh --app-store
```

### 🚀 `push.sh` - Script de Distribution
Envoi sur GitHub et sur App Store.

**Usage:**
```bash
./Scripts/push.sh [OPTIONS]
```

**Options:**
- `--github, -g` : Pousser vers GitHub Releases
- `--app-store, -a` : Pousser vers App Store Connect
- `--all, -A` : Pousser vers GitHub et App Store
- `--bump <version>` : Incrémenter la version avant de pousser
- `--commit, -c` : Auto-commit des changements de version
- `--push-commit, -p` : Auto-push du commit vers le remote
- `--verify, -v` : Seulement vérifier, ne pas pousser

**Exemples:**
```bash
./Scripts/push.sh --github
./Scripts/push.sh --bump 1.3.0 --github
./Scripts/push.sh --bump 1.3.0 --commit --push-commit --all
```

## Scripts Utilitaires

### 📝 `bump_version.sh` - Gestion des Versions
Met à jour les numéros de version dans tout le projet.

**Usage:**
```bash
./Scripts/bump_version.sh <version> [OPTIONS]
```

**Options:**
- `--commit` : Commiter automatiquement les changements de version
- `--push` : Pousser automatiquement le commit et le tag

**Exemples:**
```bash
./Scripts/bump_version.sh 1.3.0
./Scripts/bump_version.sh 1.3.0 --commit --push
```

## Menu Interactif

### 🐱 `run.sh` - Menu Principal
Script interactif pour accéder à toutes les fonctionnalités.

**Usage:**
```bash
./run.sh [OPTION]
```

**Options:**
- `--verify, -v` : Vérifier l'environnement et la configuration
- `--build, -b` : Builder l'app
- `--test, -t` : Lancer les tests
- `--run, -r` : Lancer l'app
- `--install, -i` : Installer l'app localement
- `--package, -p` : Packager l'app (DMG et PKG)
- `--sign, -s` : Signer l'app
- `--push, -u` : Pousser vers la distribution
- `--debug-all, -da` : Workflow debug complet
- `--release-all, -ra` : Workflow release complet
- `--deliver, -d` : Workflow de livraison complet
- `--app-store, -as` : Workflow de distribution App Store

**Exemples:**
```bash
./run.sh --verify
./run.sh --build --test
./run.sh --release-all
./run.sh --deliver 1.3.0
```

## Workflows Typiques

### 🔨 Développement
```bash
# Vérifier l'environnement
./Scripts/verify.sh --all

# Build et test
./Scripts/build.sh --debug --test

# Run l'app
./Scripts/build.sh --debug --run

# Ou utiliser le menu interactif
./run.sh
```

### 🚀 Release
```bash
# Build release
./Scripts/build.sh --release

# Packager
./Scripts/package.sh

# Signer
./Scripts/sign.sh --app

# Pousser vers GitHub
./Scripts/push.sh --github

# Ou workflow complet
./run.sh --release-all
```

### 🍎 App Store
```bash
# Build release
./Scripts/build.sh --release

# Packager pour App Store
./Scripts/package.sh --app-store

# Signer
./Scripts/sign.sh --app

# Pousser vers App Store
./Scripts/push.sh --app-store

# Ou workflow complet
./run.sh --app-store
```

### 🏷️ Livraison Complète
```bash
# Workflow complet avec bump de version
./run.sh --deliver 1.3.0

# Ou manuellement
./Scripts/push.sh --bump 1.3.0 --commit --push-commit
./Scripts/build.sh --release
./Scripts/package.sh
./Scripts/sign.sh --all
./Scripts/push.sh --all
```

## Variables d'Environnement

Créez un fichier `.env` à la racine du projet avec :

```bash
# Apple ID pour notarization et App Store
APPLE_ID=your-apple-id@example.com
APPLE_ID_PASSWORD=your-app-specific-password
TEAM_ID=your-team-id

# PostHog Analytics (optionnel)
POSTHOG_API_KEY=your-posthog-api-key
POSTHOG_HOST=https://app.posthog.com
```

## Prérequis

- macOS 13.0+
- Xcode Command Line Tools
- Swift 5.0+
- Git
- GitHub CLI (pour les releases GitHub)
- Certificat Apple Developer (pour la distribution)

## Notes Importantes

- Les scripts sont conçus pour macOS uniquement
- La notarization nécessite un Apple Developer Program
- L'App Store nécessite un certificat de distribution App Store
- Les builds release nécessitent un fichier `.env` avec les variables appropriées