# Axiom Flutter

Application mobile Axiom pour Android et iOS.

## Environnements

Les paramètres de compilation partagés se trouvent dans :

- `config/development.json` → `https://dev-server.ndeli.tech`
- `config/production.json` → `https://server.ndeli.tech`

Les deux configurations utilisent actuellement le même identifiant
d'application et le même projet Firebase. Installer l'une remplace donc
l'autre sur un appareil. Les paiements restent désactivés jusqu'à validation
complète de l'intégration correspondante.

Ne placez aucun secret dans ces fichiers : les valeurs passées avec
`--dart-define` sont intégrées à l'application compilée.

## Développement

Lancer l'application contre le serveur de développement :

```bash
./scripts/run_dev.sh
```

Les arguments supplémentaires sont transmis à `flutter run`, par exemple :

```bash
./scripts/run_dev.sh -d <device-id>
```

Les configurations VS Code `axiom (development server)` et
`axiom (production server)` utilisent les mêmes fichiers JSON.

## Builds

Android de développement, installable directement :

```bash
./scripts/build_dev_apk.sh
```

iOS de développement :

```bash
./scripts/build_dev_ipa.sh
```

Android de production pour le Play Store :

```bash
./scripts/build_prod_aab.sh
```

iOS de production pour App Store Connect :

```bash
./scripts/build_prod_ipa.sh
```

Les scripts de production incrémentent le numéro de build dans `pubspec.yaml`.
Ils doivent être lancés uniquement pour préparer une livraison. Le build
Android de production nécessite `android/key.properties`; le build iOS
nécessite la signature et le profil de distribution configurés dans Xcode.

## Validation

Vérifier que les scripts utilisent les bons serveurs :

```bash
bash test/scripts/build_environments_test.sh
```
