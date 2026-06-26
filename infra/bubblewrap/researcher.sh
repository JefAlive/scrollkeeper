#!/usr/bin/env bash

# Resolve os caminhos absolutos do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOCAL_HERMES_HOME="$SCRIPT_DIR/.hermes"

# Garante que a pasta local do perfil existe
mkdir -p "$LOCAL_HERMES_HOME/profiles/researcher"
touch "$LOCAL_HERMES_HOME/profiles/researcher/SOUL.md"

# Auto-inicializa o arquivo de configuração local se ele não existir
if [ ! -f "$LOCAL_HERMES_HOME/profiles/researcher/config.yaml" ]; then
    cat << 'EOF' > "$LOCAL_HERMES_HOME/profiles/researcher/config.yaml"
model:
  default: "local/llama-model"
providers:
  local:
    type: openai
    base_url: "http://127.0.0.1:8000/v1"
    api_key: "local"
EOF
fi

# Carrega variáveis de ambiente adicionais, se houverem
if [ -f "$SCRIPT_DIR/env/researcher.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/env/researcher.env" | xargs)
fi

# Executa o Bubblewrap
bwrap \
  --ro-bind /usr /usr \
  --ro-bind /bin /bin \
  --ro-bind /lib /lib \
  --ro-bind /lib64 /lib64 \
  --ro-bind /etc /etc \
  --ro-bind /var /var \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --unshare-pid \
  --unshare-ipc \
  --unshare-uts \
  --ro-bind "$HOME/.hermes" "$HOME/.hermes" \
  --ro-bind "$HOME/.local/bin" "$HOME/.local/bin" \
  --bind "$LOCAL_HERMES_HOME" "$HOME/.hermes_project" \
  --ro-bind "$PROJECT_ROOT" "$PROJECT_ROOT" \
  --ro-bind "$PROJECT_ROOT/hermes/profiles/researcher.md" "$HOME/.hermes_project/profiles/researcher/SOUL.md" \
  --bind "$PROJECT_ROOT/hermes/tasks" "$PROJECT_ROOT/hermes/tasks" \
  --bind "$PROJECT_ROOT/hermes/epics" "$PROJECT_ROOT/hermes/epics" \
  --bind "$PROJECT_ROOT/hermes/memory" "$PROJECT_ROOT/hermes/memory" \
  --setenv HOME "$HOME" \
  --setenv HERMES_HOME "$HOME/.hermes_project" \
  --chdir "$PROJECT_ROOT" \
  "$HOME/.local/bin/hermes" -p researcher chat "$@"