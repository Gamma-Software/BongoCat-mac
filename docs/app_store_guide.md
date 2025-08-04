# 🍎 BongoCat App Store Deployment Guide

Ce guide vous accompagne dans le processus de déploiement de BongoCat sur le Mac App Store.

## 📋 Prérequis

### 1. Apple Developer Program
- **Adhésion Apple Developer Program** (99$/an)
- **Certificat de distribution App Store** installé
- **Profil de provisionnement App Store** configuré

### 2. Configuration Xcode
- **Xcode** installé (dernière version recommandée)
- **Certificats et profils** synchronisés via Xcode
- **App ID** configuré dans Apple Developer Portal

### 3. App Store Connect
- **Compte App Store Connect** configuré
- **App** créée dans App Store Connect
- **Métadonnées** préparées (description, captures d'écran, etc.)

## 🔧 Configuration Initiale

### 1. Certificat de Distribution
```bash
# Vérifier les certificats disponibles
security find-identity -v -p codesigning

# Installer le certificat de distribution App Store
# (Téléchargé depuis Apple Developer Portal)
```

### 2. Profil de Provisionnement
```bash
# Emplacements des profils de provisionnement
~/Library/MobileDevice/Provisioning Profiles
~/Library/Developer/Xcode/Provisioning Profiles
```

### 3. App ID Configuration
- **Bundle ID**: `com.leaptech.bongocat`
- **Capacités**: Accessibilité (Accessibility)
- **Distribution**: App Store

## 🚀 Processus de Déploiement

### Option 1: Script Automatisé (Recommandé)
```bash
# Déployer pour App Store
./run.sh --app-store

# Ou directement avec le script de packaging
./Scripts/package_app.sh --app_store --sign-certificate
```

### Option 2: Menu Interactif
```bash
# Lancer le menu interactif
./run.sh

# Sélectionner l'option 9: "Build release, sign and package for App Store distribution"
```

## 📦 Fichiers Générés

Le script génère les fichiers suivants :
- **`Build/BongoCat-{VERSION}-AppStore.ipa`** - Package App Store
- **`Build/package/BongoCat.app`** - Bundle d'application signé

## 🔍 Vérification

### Vérifier la Signature
```bash
# Vérifier la signature du bundle
codesign --verify --verbose Build/package/BongoCat.app

# Vérifier les détails de signature
codesign --display --verbose Build/package/BongoCat.app
```

### Vérifier le Package IPA
```bash
# Lister le contenu du package IPA
unzip -l Build/BongoCat-{VERSION}-AppStore.ipa

# Vérifier la structure
unzip -q Build/BongoCat-{VERSION}-AppStore.ipa -d /tmp/ipa_check
ls -la /tmp/ipa_check/Payload/
```

## 📤 Soumission App Store

### Méthode 1: Xcode Organizer
1. **Ouvrir Xcode**
2. **Window > Organizer**
3. **Sélectionner l'app BongoCat**
4. **Distribute App > App Store Connect**
5. **Upload le fichier .ipa généré**

### Méthode 2: Transporter App
1. **Ouvrir Transporter** (depuis App Store)
2. **Ajouter le fichier .ipa**
3. **Vérifier et uploader**

### Méthode 3: Application Loader
1. **Ouvrir Application Loader**
2. **Sélectionner l'app**
3. **Upload le package .ipa**

## 📋 Métadonnées App Store

### Informations Requises
- **Nom de l'app**: BongoCat
- **Description**: Description détaillée de l'app
- **Mots-clés**: cat, keyboard, overlay, streaming, animation
- **Catégorie**: Productivity ou Utilities
- **Captures d'écran**: 1280x800 minimum
- **Icône**: 1024x1024 PNG

### Contenu de l'App
- **Fonctionnalités**: Liste des fonctionnalités principales
- **Compatibilité**: macOS 11.0+
- **Permissions**: Accessibilité requise
- **Prix**: Gratuit ou payant

## 🔐 Sécurité et Permissions

### Entitlements
Le fichier `BongoCat.entitlements` contient :
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.personal-information.addressbook</key>
    <true/>
    <key>com.apple.security.personal-information.calendars</key>
    <true/>
    <key>com.apple.security.personal-information.photos-library</key>
    <true/>
</dict>
</plist>
```

### Permissions Système
- **Accessibilité**: Requise pour la surveillance du clavier
- **Événements système**: Pour les interactions clavier/souris
- **Fenêtres transparentes**: Pour l'overlay

## 🐛 Dépannage

### Erreurs Communes

#### Certificat Non Trouvé
```bash
# Vérifier les certificats
security find-identity -v -p codesigning

# Réinstaller le certificat si nécessaire
# Télécharger depuis Apple Developer Portal
```

#### Profil de Provisionnement Manquant
```bash
# Vérifier les profils installés
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Créer un profil dans Apple Developer Portal
# Bundle ID: com.leaptech.bongocat
# Distribution: App Store
```

#### Erreur de Signature
```bash
# Nettoyer et resigner
codesign --remove-signature BongoCat.app
codesign --force --sign "Apple Distribution: Your Name" BongoCat.app
```

### Logs de Débogage
```bash
# Activer les logs détaillés
export CODESIGN_ALLOCATE=/usr/bin/codesign_allocate
codesign --verbose=4 --deep --force --sign "Apple Distribution: Your Name" BongoCat.app
```

## 📈 Suivi et Mise à Jour

### Versioning
- **Format**: MAJOR.MINOR.PATCH (ex: 1.6.0)
- **Build Number**: Automatique via script
- **Changelog**: Mis à jour dans CHANGELOG.md

### Mise à Jour
```bash
# Bumper la version
./Scripts/bump_version.sh 1.6.1

# Reconstruire et redéployer
./run.sh --app-store
```

## 🎯 Bonnes Pratiques

### Avant la Soumission
1. **Tester** l'app sur différentes versions de macOS
2. **Vérifier** toutes les fonctionnalités
3. **Préparer** les métadonnées complètes
4. **Valider** la signature et le package

### Pendant la Review
1. **Répondre rapidement** aux questions d'Apple
2. **Fournir** des informations détaillées si nécessaire
3. **Tester** les builds de test si demandé

### Après l'Approbation
1. **Surveiller** les crashs et feedback
2. **Mettre à jour** régulièrement l'app
3. **Répondre** aux avis utilisateurs

## 📞 Support

### Ressources Utiles
- **Apple Developer Documentation**: https://developer.apple.com/documentation/
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **App Store Connect Help**: https://help.apple.com/app-store-connect/

### Contact
- **Apple Developer Support**: https://developer.apple.com/contact/
- **App Store Connect Support**: Via App Store Connect

---

**Note**: Ce guide est spécifique à BongoCat. Pour d'autres apps, adapter les Bundle IDs et configurations selon vos besoins.