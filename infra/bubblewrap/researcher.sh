#!/usr/bin/env bash

# Resolve os caminhos do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOCAL_HERMES_HOME="$SCRIPT_DIR/.hermes"
THORIUM_BIN="thorium-browser"

# Garante existência das pastas necessárias
mkdir -p "$LOCAL_HERMES_HOME/profiles/researcher"
mkdir -p "$PROJECT_ROOT/research"
touch "$LOCAL_HERMES_HOME/profiles/researcher/SOUL.md"

# Auto-inicializa a config do profile se não existir
#if [ ! -f "$LOCAL_HERMES_HOME/profiles/researcher/config.yaml" ]; then
    cat << 'EOF' > "$LOCAL_HERMES_HOME/profiles/researcher/config.yaml"
model:
  default: "llama-model"
  provider: "custom"
  base_url: "http://127.0.0.1:8000/v1"
  api_key: "local"
web:
  search_backend: "searxng"
browser:
  cdp_url: "http://localhost:9222"
EOF
#fi

# Carrega as variáveis de ambiente
if [ -f "$SCRIPT_DIR/env/researcher.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/env/researcher.env" | xargs)
fi

# Detecção do interpretador Python
PYTHON_REAL_PATH=$(readlink -f "$HOME/.hermes/hermes-agent/venv/bin/python3" 2>/dev/null)
EXTRA_BINDS=()

if [[ "$PYTHON_REAL_PATH" == "$HOME/"* ]]; then
    RELATIVE_PATH="${PYTHON_REAL_PATH#$HOME/}"
    TOOL_DIR="${RELATIVE_PATH%%/*}"
    PYTHON_HOME_TOOL="$HOME/$TOOL_DIR"
    
    if [ -d "$PYTHON_HOME_TOOL" ]; then
        EXTRA_BINDS+=(--ro-bind "$PYTHON_HOME_TOOL" "$PYTHON_HOME_TOOL")
    fi
fi

# Inicialização automática do Thorium
if [ -n "$THORIUM_BIN" ]; then
    echo "Iniciando o Thorium local no WSL (Headless)..."
    
    "$THORIUM_BIN" \
      --remote-debugging-port=9222 \
      --incognito \
      --start-minimized \
      --no-first-run \
      --no-default-browser-check \
      --disable-gpu \
      --disable-extensions >/dev/null 2>&1 &
      #--headless=new
      
    TIMEOUT_LIMIT=10 # Limite máximo de 10 segundos
    COUNT=0
    while ! curl -s http://127.0.0.1:9222/json/version >/dev/null 2>&1; do
        sleep 0.1
        COUNT=$((COUNT + 1))
        
        # Se atingir o tempo limite, exibe aviso e prossegue
        if [ "$COUNT" -ge "$((TIMEOUT_LIMIT * 10))" ]; then
            echo "Aviso: Tempo limite de 10s esgotado ao aguardar o Thorium. Continuando de forma assíncrona..."
            break
        fi
    done
    echo "Thorium iniciado e respondendo na porta 9222!"
else
    echo "Aviso: Executável do Thorium não foi encontrado no WSL. Rodando sem suporte a browser físico."
fi

# Executa o Bubblewrap
bwrap \
  --ro-bind /usr /usr \
  --symlink /usr/bin /bin \
  --symlink /usr/sbin /sbin \
  --symlink /usr/lib /lib \
  --symlink /usr/lib64 /lib64 \
  --ro-bind /etc /etc \
  --ro-bind /var /var \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --unshare-pid \
  --unshare-ipc \
  --unshare-uts \
  --ro-bind-try "$HOME/.nvm" "$HOME/.nvm" \
  --ro-bind-try "$HOME/.cargo" "$HOME/.cargo" \
  --ro-bind "$HOME/.hermes" "$HOME/.hermes" \
  --bind "$HOME/.hermes/hermes-agent" "$HOME/.hermes/hermes-agent" \
  --ro-bind "$HOME/.local/bin" "$HOME/.local/bin" \
  "${EXTRA_BINDS[@]}" \
  --bind "$LOCAL_HERMES_HOME" "$HOME/.hermes_project" \
  --ro-bind "$PROJECT_ROOT" "$PROJECT_ROOT" \
  --ro-bind "$PROJECT_ROOT/hermes/profiles/researcher/SOUL.md" "$HOME/.hermes_project/profiles/researcher/SOUL.md" \
  --bind "$PROJECT_ROOT/research" "$PROJECT_ROOT/research" \
  --bind "$PROJECT_ROOT/hermes/tasks" "$PROJECT_ROOT/hermes/tasks" \
  --setenv HOME "$HOME" \
  --setenv HERMES_HOME "$HOME/.hermes_project" \
  --setenv HERMES_TUI_DIR "$HOME/.hermes/hermes-agent/ui-tui" \
  --setenv PATH "$PATH" \
  --setenv npm_config_loglevel "verbose" \
  --chdir "$PROJECT_ROOT" \
  "$HOME/.local/bin/hermes" -p researcher chat "$@" --tui

# Encerra o Thorium
echo "Encerrando o Thorium local..."
PIDS_FINAIS=$(ps -u "$USER" -o pid,args | grep -i "thorium" | grep -v -E "grep|researcher.sh" | awk '{print $1}')
if [ -n "$PIDS_FINAIS" ]; then
  echo "$PIDS_FINAIS" | xargs kill -9 >/dev/null 2>&1
fi