#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOCAL_HERMES_HOME="$SCRIPT_DIR/.hermes"

mkdir -p "$LOCAL_HERMES_HOME/profiles/researcher"
mkdir -p "$PROJECT_ROOT/researchs"
touch "$LOCAL_HERMES_HOME/profiles/researcher/SOUL.md"

if [ ! -f "$LOCAL_HERMES_HOME/profiles/researcher/config.yaml" ]; then
    cat << 'EOF' > "$LOCAL_HERMES_HOME/profiles/researcher/config.yaml"
model:
  default: "llama-model"
  provider: "custom"
  base_url: "http://127.0.0.1:8000/v1"
  api_key: "local"
EOF
fi

if [ -f "$SCRIPT_DIR/env/researcher.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/env/researcher.env" | xargs)
fi

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
  --ro-bind "$HOME/.local/bin" "$HOME/.local/bin" \
  "${EXTRA_BINDS[@]}" \
  --bind "$LOCAL_HERMES_HOME" "$HOME/.hermes_project" \
  --ro-bind "$PROJECT_ROOT" "$PROJECT_ROOT" \
  --ro-bind "$PROJECT_ROOT/hermes/profiles/researcher/SOUL.md" "$HOME/.hermes_project/profiles/researcher/SOUL.md" \
  --bind "$PROJECT_ROOT/research" "$PROJECT_ROOT/research" \
  --bind "$PROJECT_ROOT/hermes/tasks" "$PROJECT_ROOT/hermes/tasks" \
  --setenv HOME "$HOME" \
  --setenv HERMES_HOME "$HOME/.hermes_project" \
  --setenv PATH "$PATH" \
  --chdir "$PROJECT_ROOT" \
  "$HOME/.local/bin/hermes" -p researcher chat "$@"