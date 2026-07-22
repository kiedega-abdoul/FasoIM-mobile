# FasoIM — Étape 7

Base Flutter de l'application mobile FasoIM.

## État actuel

- Splash avec logo officiel FasoIM
- Accueil public avec diaporama d'images
- Menu public fonctionnel
- Trois services essentiels
- Adresse du backend centralisée dans `lib/core/config/api_config.dart`
- Aucune information technique du backend affichée dans l'interface

## Lancement

```powershell
flutter pub get
flutter analyze
flutter run
```

## Diagnostic backend

Le menu de l'accueil contient **Tester la connexion au backend**. Cette page vérifie sans créer de données :
- le health-check Django ;
- les sessions publiques ouvertes ;
- les routes de demande et suivi volontaire ;
- la consultation des informations d'arrivée ;
- les routes publiques d'attestation ;
- l'authentification JWT des acteurs ;
- la documentation Swagger.

Une réponse HTTP 400 aux tests POST vides signifie que la route est joignable et que sa validation fonctionne.
