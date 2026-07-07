# ClaudeContainer

Image Docker pour démarrer rapidement plusieurs sessions Claude Code distinctes, déjà authentifiées, pilotables à distance depuis claude.ai ou l'app Claude (mode **Remote Control**).

Inclus dans l'image :

- **Claude Code** (installé via npm, auto-update désactivé)
- **uv / uvx** pour les projets Python
- **Skills superpowers** (plugin `superpowers@superpowers-marketplace`) installés par défaut
- **git + client SSH** avec `gitlab.com` pré-approuvé dans `known_hosts`

## 1. Générer le token (une seule fois)

Sur votre machine, avec un abonnement Claude :

```bash
claude setup-token
```

Gardez le token affiché (par exemple dans un gestionnaire de secrets ou `~/.claude-token`). Il est passé **au démarrage du conteneur**, jamais copié dans l'image — ne le passez pas en `--build-arg`, il resterait visible dans les layers.

## 2. Construire l'image

```bash
docker build -t claude-code .
```

Une GitHub Action ([`.github/workflows/build-image.yml`](.github/workflows/build-image.yml)) build et publie aussi l'image sur GHCR à chaque push sur `main`. Pour l'utiliser sans build local :

```bash
docker pull ghcr.io/quentinrillet/claudecontainer:latest
# puis remplacez 'claude-code' par cette image, ou :
export IMAGE=ghcr.io/quentinrillet/claudecontainer:latest
```

## 3. Démarrer des sessions

### Avec le script fourni

```bash
export CLAUDE_CODE_OAUTH_TOKEN=<token>
export GIT_USER_NAME="Quentin Rillet"
export GIT_USER_EMAIL="quentin.rillet@gmail.com"

./new-session.sh projet-api ~/dev/projet-api
./new-session.sh projet-data ~/dev/projet-data
```

Chaque appel lance un conteneur distinct en mode `claude remote-control`. Les sessions apparaissent dans claude.ai / l'app Claude sous le nom `<nom>-<suffixe>` (le préfixe vient du hostname du conteneur).

### À la main

```bash
docker run -d --rm \
  --name claude-monprojet \
  --hostname monprojet \
  -e CLAUDE_CODE_OAUTH_TOKEN=<token> \
  -v ~/.ssh:/ssh:ro \
  -v ~/dev/monprojet:/workspace \
  claude-code
```

### Session interactive dans le terminal

La commande par défaut est remplaçable, par exemple pour une session classique :

```bash
docker run -it --rm \
  -e CLAUDE_CODE_OAUTH_TOKEN=<token> \
  -v ~/.ssh:/ssh:ro \
  -v "$PWD:/workspace" \
  claude-code claude
```

## Clés SSH (push vers GitLab)

Montez votre dossier `.ssh` en lecture seule sur `/ssh` :

```bash
-v ~/.ssh:/ssh:ro
```

Au démarrage, l'entrypoint copie les clés dans le conteneur avec les bonnes permissions (600) et ajoute la clé d'hôte de `gitlab.com` dans `known_hosts`. Pour une instance GitLab auto-hébergée (ou d'autres hôtes) :

```bash
-e GIT_SSH_HOSTS="gitlab.com gitlab.mon-entreprise.com"
```

## Variables d'environnement

| Variable | Rôle | Défaut |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | Token généré par `claude setup-token` (**requis**, ou `ANTHROPIC_API_KEY`) | — |
| `ANTHROPIC_API_KEY` | Alternative : clé API Anthropic (facturation API) | — |
| `GIT_USER_NAME` / `GIT_USER_EMAIL` | Identité git pour les commits | — |
| `GIT_SSH_HOSTS` | Hôtes git à ajouter dans `known_hosts` (séparés par des espaces) | `gitlab.com` |
| `CLAUDE_REMOTE_CONTROL_SESSION_NAME_PREFIX` | Préfixe du nom de session Remote Control | hostname du conteneur |

## Commandes utiles

```bash
docker logs -f claude-monprojet      # suivre la session
docker stop claude-monprojet         # arrêter la session (conteneur supprimé, --rm)
docker ps --filter name=claude-      # lister les sessions en cours
```
