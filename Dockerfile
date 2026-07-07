# syntax=docker/dockerfile:1
FROM node:22-bookworm-slim

ARG CLAUDE_CODE_VERSION=latest

# Outils de base : git + ssh pour pousser sur GitLab, curl/ca-certificates pour le réseau
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        openssh-client \
        curl \
        ca-certificates \
        jq \
        procps \
    && rm -rf /var/lib/apt/lists/*

# uv + uvx (gestionnaire de projets Python)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Claude Code
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# Utilisateur non-root + dossier de travail
RUN useradd -m -s /bin/bash claude \
    && mkdir -p /workspace \
    && chown claude:claude /workspace

USER claude
ENV HOME=/home/claude
WORKDIR /workspace

# L'image est immuable : pas d'auto-update de Claude Code au runtime
ENV DISABLE_AUTOUPDATER=1
# Les volumes montés peuvent être sur un autre filesystem
ENV UV_LINK_MODE=copy

# Évite l'écran d'onboarding au premier lancement
RUN echo '{"hasCompletedOnboarding": true}' > "$HOME/.claude.json"

# Skills superpowers installés par défaut
RUN claude plugin marketplace add obra/superpowers-marketplace \
    && claude plugin install superpowers@superpowers-marketplace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# Par défaut : serveur Remote Control, pilotable depuis claude.ai ou l'app Claude
CMD ["claude", "remote-control"]
