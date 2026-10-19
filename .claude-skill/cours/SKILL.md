---
name: cours
description: Crée un cours détaillé en Markdown (explications, exemples, schémas, pièges, quiz) sur un concept technique que l'utilisateur ne connaît pas, et l'enregistre dans sa base de connaissances ~/all-memory, quel que soit le projet courant. Utiliser quand l'utilisateur dit "fais-moi un cours sur X", "crée-moi un cours", "je ne connais pas ce concept", "explique-moi X en détail", "/cours X".
---

# Créer un cours dans la base de connaissances

La base de cours se trouve TOUJOURS dans le dossier personnel de l'utilisateur :

    KB = $HOME/all-memory

Avant toute chose, résous le chemin absolu avec `echo "$HOME/all-memory"` et utilise ce résultat partout (les outils de fichiers exigent des chemins absolus, sans `~`). Si ce dossier n'existe pas, arrête-toi et dis à l'utilisateur de cloner son dépôt `all-memory` dans son dossier personnel puis de lancer `install.sh`.

N'écris JAMAIS le cours dans le projet courant. Utilise toujours des chemins absolus sous `KB`, même si le répertoire de travail est ailleurs.

## Étapes

1. **Identifier le concept.** Prends l'argument passé (`/cours <concept>`). S'il n'y en a pas, déduis-le de la conversation et du code récemment discuté dans le projet courant. Si c'est vraiment ambigu, demande en une phrase.

2. **Vérifier l'existant.** Lis `KB/INDEX.md` et cherche le concept (`grep -ril "<mots-clés>" KB --include=*.md`).
   - Si un cours existe déjà : **complète-le** (nouvelle section, nouveaux exemples, nouvelle entrée dans « Vu dans le projet ») au lieu de créer un doublon.

3. **Choisir le thème.** Liste les dossiers de `KB` (`ls KB`). Choisis le plus pertinent parmi : `reseaux`, `git`, `web`, `langages`, `bases-de-donnees`, `systeme`, `securite`, `algorithmes`, `architecture`, `devops`, ou tout autre dossier existant. Si aucun ne convient, crée un nouveau dossier en kebab-case, sans accents (ex. `machine-learning`). Pour un concept propre à un langage, utilise un sous-dossier : `langages/python/`, `langages/javascript/`…

4. **Écrire le cours** dans `KB/<theme>/<concept-en-kebab-case>.md` en suivant **exactement** la structure de `KB/_template.md` (lis-le d'abord). Exigences de qualité :
   - En français ; garde les termes techniques anglais entre parenthèses la première fois (ex. « poignée de main (handshake) »).
   - Progressif : part de l'intuition et d'une analogie, puis monte vers le détail technique.
   - Au moins 3 exemples de code commentés, du plus simple au plus réaliste, exécutables quand c'est possible, avec la sortie attendue.
   - Un schéma (```mermaid ou ASCII) dès que le concept a un flux, une structure ou des étapes.
   - Une section « Pièges courants » concrète.
   - Un quiz de 3 questions, réponses repliées dans `<details>`.
   - Liens vers la documentation officielle uniquement (pas d'URL inventée).

5. **Ancrer dans le projet.** Remplis la section « Vu dans le projet » avec : le chemin absolu du projet courant (répertoire de travail), le fichier concerné, et un court extrait du vrai code qui a soulevé la question, expliqué ligne par ligne. Si le cours n'est lié à aucun code, écris « Demandé hors contexte de code ».

6. **Relier.** Mets à jour `KB/INDEX.md` : ajoute `- [Titre](theme/fichier.md) — résumé en une ligne` sous le bon titre de thème (crée le titre `## <Thème>` s'il manque, garde l'ordre alphabétique des entrées). Ajoute des liens relatifs dans « Voir aussi » vers les cours existants liés, et ajoute le lien inverse dans ces cours-là.
   Supprime le `.gitkeep` du dossier thème s'il contient désormais un cours.

7. **Répondre** dans le terminal en 3–4 lignes : l'idée clé du concept + le chemin du fichier créé ou complété. Ne recopie pas le cours entier dans la réponse.
