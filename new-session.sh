#!/usr/bin/env bash
# Démarre une nouvelle session Claude Code distincte en mode Remote Control.
#
# Usage :
#   export CLAUDE_CODE_OAUTH_TOKEN=<token>   # généré une fois via 'claude setup-token'
#   ./new-session.sh <nom> [dossier-projet]
#
# Exemple :
#   ./new-session.sh projet-api ~/dev/projet-api
#   ./new-session.sh scratch                 # utilise le dossier courant
set -euo pipefail

NAME=${1:?usage: new-session.sh <nom> [dossier-projet]}
DIR=$(cd "${2:-$PWD}" && pwd)
IMAGE=${IMAGE:-claude-code}

docker run -d --rm \
    --name "claude-$NAME" \
    --hostname "$NAME" \
    -e CLAUDE_CODE_OAUTH_TOKEN \
    -e ANTHROPIC_API_KEY \
    -e GIT_USER_NAME \
    -e GIT_USER_EMAIL \
    -e GIT_SSH_HOSTS \
    -v "$HOME/.ssh:/ssh:ro" \
    -v "$DIR:/workspace" \
    "$IMAGE"

echo "Session '$NAME' démarrée sur $DIR"
echo "Retrouvez-la sur https://claude.ai (ou l'app Claude) sous le nom '$NAME-...'"
echo "Logs : docker logs -f claude-$NAME   |   Arrêt : docker stop claude-$NAME"
