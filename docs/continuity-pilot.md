# Pilote FoldReady : continuité des parcours

Document de travail pour une démonstration et des entretiens. Offre non publiée.

## Proposition

Trouvez à quel moment un changement de fenêtre fait perdre le travail de vos utilisateurs.

FoldReady reprend un parcours de test, insère une transition aux étapes convenues et vérifie
les valeurs qui doivent rester présentes. Lorsqu'un invariant change, le rapport donne les
étapes de reproduction et les observations avant et après.

## Démonstration en cinq minutes

1. Montrer un formulaire avec son nom et ses détails de livraison.
2. Exécuter le contrôle sans transition : les données restent présentes.
3. Exécuter la variante défectueuse avec rotation : le nom disparaît.
4. Ouvrir le rapport et la capture ; retrouver le point de transition et la valeur perdue.
5. Exécuter la variante corrigée et montrer le résultat du même contrôle.

Le panier illustre ensuite une action comptée deux fois ; le brouillon illustre une perte de texte.
Ce sont des défauts injectés dans une démonstration locale. Le panier ne déclenche aucun paiement.
La rotation sur iPad ne constitue pas une validation du pliage sur iPhone Duo.

## Offre expérimentale à tester

Prix proposé : 199 EUR par application, avec une heure d'installation incluse et un parcours convenu.
Le devis précise le traitement fiscal applicable. Le périmètre fixe le build, le SDK, l'environnement,
les transitions disponibles, les valeurs à préserver et les critères d'acceptation.

La livraison comprend les scénarios exécutables, le rapport et les preuves disponibles.
Les corrections de l'application, les parcours supplémentaires, le test sur téléphone physique
et un moteur de paiement réel ne sont pas inclus. Aucun abonnement.

La date de livraison est convenue après vérification du projet et des outils nécessaires.
Le prototype actuel ne traite que la démonstration livrée dans le dépôt. L'adaptation à un projet
client doit être vérifiée avant de lui promettre un pilote. Aucun gain de temps garanti.

## Entretien de qualification

- Quelle version devez-vous livrer, à quelle date et qui décide du budget ?
- Quel parcours peut perdre une saisie ou répéter une action lors d'un changement de fenêtre ?
- Avez-vous déjà observé ce défaut ? Pouvez-vous montrer un exemple anonymisé ?
- Comment le testez-vous aujourd'hui ? Quel temps cette vérification prend-elle ?
- Quels tests et environnements pouvez-vous fournir pour comparer les deux méthodes ?
- À quelles conditions engageriez-vous 199 EUR pour ce parcours précis ?

Retenir les objections et les solutions existantes qui suffisent déjà au prospect.
Un intérêt pour le Duo ou un compliment sur la démo ne compte pas comme engagement commercial.

## Message préparé, non envoyé

Bonjour,

Je teste FoldReady sur un problème précis : les données perdues ou les actions répétées quand
une app iOS change de taille au milieu d'un parcours.

La démo permet de reproduire ces défauts sur un formulaire, un panier et un brouillon.
Je cherche à comparer cette approche avec les tests déjà utilisés par une équipe qui prépare
une livraison. Le support du pliage Duo reste à vérifier avec les outils Apple disponibles.

Avez-vous un parcours pour lequel cette vérification prend du temps aujourd'hui ?

Guillaume

## Suivi privé

Pour chacun des cinq entretiens : interlocuteur et rôle, livraison datée, défaut observé,
solution actuelle, temps passé, accès technique possible, décisionnaire, objection, prix discuté,
prochaine étape et preuve d'engagement. Aucun contact ni engagement n'est enregistré à ce stade.
Ne pas placer les coordonnées ou données client dans ce dépôt public.
