# all-memory — mes cours techniques

Base de connaissances personnelle : un cours Markdown par concept, rangé par thème.

## Utilisation
Depuis **n'importe quel projet**, dans Claude Code :

```
/cours 'description'
```

ou simplement :

> je ne connais pas ce concept, fais-moi un cours dessus

Le skill écrit toujours le cours ici (`~/all-memory/<theme>/<concept>.md`), jamais dans
le projet courant, puis met à jour [INDEX.md](INDEX.md). Si le cours existe déjà, il est complété.

## Installation sur une nouvelle machine / un autre utilisateur
```bash
git clone <url-du-depot> ~/all-memory
~/all-memory/install.sh
```
Le dépôt doit être cloné exactement dans `~/all-memory`. `install.sh` crée le lien
`~/.claude/skills/cours -> ~/all-memory/.claude-skill/cours`.

Pour synchroniser : `git pull` avant de travailler, `git add -A && git commit -m "..." && git push` après.

## Organisation
- [INDEX.md](INDEX.md) — sommaire de tous les cours
- [_template.md](_template.md) — structure de chaque cours
- `.claude-skill/cours/SKILL.md` — la commande `/cours` (source unique, versionnée)
- `install.sh` — installe la commande sur la machine
- Un dossier par thème : `reseaux/`, `git/`, `web/`, `langages/`, `bases-de-donnees/`,
  `systeme/`, `securite/`, `algorithmes/`, `architecture/`, `devops/`
  (de nouveaux thèmes sont créés au besoin)
