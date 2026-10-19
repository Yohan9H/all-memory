#!/usr/bin/env bash
# Installe la commande /cours de Claude Code en liant le skill de ce dépôt
# dans ~/.claude/skills. À lancer une fois par machine / utilisateur.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED="$HOME/all-memory"
SKILL_SRC="$REPO_DIR/.claude-skill/cours"
SKILL_DST="$HOME/.claude/skills/cours"

if [ "$REPO_DIR" != "$EXPECTED" ]; then
  echo "⚠️  Le dépôt est dans $REPO_DIR mais le skill attend $EXPECTED."
  echo "   Déplace-le (mv \"$REPO_DIR\" \"$EXPECTED\") puis relance ce script."
  exit 1
fi

mkdir -p "$HOME/.claude/skills"

if [ -L "$SKILL_DST" ]; then
  rm "$SKILL_DST"
elif [ -e "$SKILL_DST" ]; then
  backup="$SKILL_DST.bak.$(date +%Y%m%d%H%M%S)"
  echo "Un skill 'cours' existe déjà : sauvegarde dans $backup"
  mv "$SKILL_DST" "$backup"
fi

ln -s "$SKILL_SRC" "$SKILL_DST"
echo "✅ /cours installé : $SKILL_DST -> $SKILL_SRC"
echo "   Ouvre une nouvelle session Claude Code pour l'utiliser."
