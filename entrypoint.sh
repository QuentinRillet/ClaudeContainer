#!/usr/bin/env bash
set -euo pipefail

# --- Token d'authentification (obligatoire) -------------------------------
if [ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo "ERREUR : aucun token fourni." >&2
    echo "Générez un token longue durée avec 'claude setup-token' puis lancez :" >&2
    echo "  docker run -e CLAUDE_CODE_OAUTH_TOKEN=<token> ..." >&2
    echo "ou utilisez une clé API :" >&2
    echo "  docker run -e ANTHROPIC_API_KEY=<clé> ..." >&2
    exit 1
fi

# --- Clés SSH (montées en lecture seule sur /ssh) --------------------------
# docker run -v ~/.ssh:/ssh:ro ...
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -d /ssh ]; then
    cp -RL /ssh/. "$HOME/.ssh/"
    find "$HOME/.ssh" -type f -exec chmod 600 {} +
    find "$HOME/.ssh" -type f -name '*.pub' -exec chmod 644 {} +
fi

# --- known_hosts (GitLab par défaut, hôtes supplémentaires via GIT_SSH_HOSTS)
touch "$HOME/.ssh/known_hosts"
chmod 600 "$HOME/.ssh/known_hosts"
for host in ${GIT_SSH_HOSTS:-gitlab.com}; do
    if ! ssh-keygen -F "$host" -f "$HOME/.ssh/known_hosts" >/dev/null 2>&1; then
        ssh-keyscan -H "$host" >> "$HOME/.ssh/known_hosts" 2>/dev/null \
            || echo "AVERTISSEMENT : ssh-keyscan $host a échoué" >&2
    fi
done

# --- Identité git -----------------------------------------------------------
if [ -n "${GIT_USER_NAME:-}" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi
# Les dépôts montés en volume appartiennent souvent à un autre UID
git config --global --add safe.directory '*'

exec "$@"
