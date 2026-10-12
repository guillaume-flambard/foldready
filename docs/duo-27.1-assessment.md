# État Duo après les API iOS 27.1

Évaluation au 22 septembre 2026, à partir des sources Apple publiées. Le terme pertinent
est **iOS 27.1 / Xcode 27.1**, pas iOS ou macOS 17. Le dépôt local a Xcode 27.0 (27A266a) et
ne contient pas de type de simulateur Duo : aucune exécution Duo ne peut encore être
attestée ici.

## Ce qui a changé côté Apple

- Une app fonctionne sans recompilation, mais le lien avec le SDK iOS 27.1 donne enfin le
  plein écran, y compris sous la barre d’état et la caméra. Xcode 27.1 et Device Hub sont
  la voie officielle pour ouvrir, fermer, pivoter et plier le simulateur. [Prepare your app
  for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)
- Les décisions de mise en page doivent dépendre de l’espace réel : size classes,
  traits, bounds de scène et safe areas. L’écran interne est regular/regular et ignore les
  orientations supportées. `UIScreen.main`, l’idiome et l’orientation ne sont donc pas des
  variables de layout fiables. [Apple](https://developer.apple.com/videos/play/tech-talks/111461/)
- iOS 27.1 apporte les outils qui manquaient aux UI sur mesure : `ReservedRegion` /
  `UIViewReservedRegion` pour le pli, les caméras et les éléments système, et
  `ArrangementView` / `UIArrangementViewController` avec les arrangements split et overlay.
  Le signal de charnière (`onHingeChange` / `UIHingeInteraction`) sert à des interactions ou
  des effets, pas à calculer la mise en page. [Layouts adaptatifs](https://developer.apple.com/videos/play/tech-talks/111463/),
  [charnière et scènes](https://developer.apple.com/videos/play/tech-talks/111464/)
- Toutes les apps participent au Split View et Duo peut avoir plusieurs scènes de la même
  app. La création d’une nouvelle scène est toutefois indisponible sur l’écran externe : le
  produit doit gérer l’échec, ou employer `UIWindowSceneActivationAction` qui se masque
  quand elle est impossible. [Apple](https://developer.apple.com/videos/play/tech-talks/111464/)

## Ce que FoldReady couvre déjà

- Le scan signale les références à `UIScreen.main`, les branches d’idiome, les orientations
  figées et le plancher de build Xcode 27.1. Cela correspond directement aux garde-fous
  publiés par Apple.
- Les quatre zones Apple pour les layouts personnalisés sont déjà des avis séparés, hors
  score et hors gate : régions réservées, arrangements, barres verticales et direction de
  caméra. Cette prudence reste juste : l’absence d’une API 27.1 dans le source n’est pas un
  défaut lorsque les conteneurs système suffisent.
- Le contrat garde explicitement `duo_runtime_verified: false`; le prototype de continuité
  ne fait que la rotation sur simulateur et affirme lui-même ne pas supporter le pliage Duo.

## Écart à fermer

Le projet est aujourd’hui un bon instrument de **pré-revue statique**, pas un validateur Duo.
Le prochain jalon technique, à réaliser seulement pour une revue client effectivement vendue,
est un passage Xcode 27.1 : construire le vrai target, enregistrer le SDK lié, puis exécuter
les parcours convenus sur écran externe/interne, poses ouverte-fermée-partiellement pliée,
Split View et régions réservées. Il faut garder les résultats par build, runtime et pose.
Ne pas promettre une couverture de charnière automatisée avant qu’un essai Device Hub répété
ait montré que ses contrôles sont pilotables de façon fiable.

## Sources primaires

- [Portail Apple Developer iPhone Duo](https://developer.apple.com/iphone-duo/)
- [Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)
- [Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111463/)
- [Leverage multiple displays and scenes on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111464/)
