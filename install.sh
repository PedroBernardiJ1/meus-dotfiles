#!/usr/bin/env bash
# install.sh — prepara um container novo: zsh + oh-my-zsh + powerlevel10k, os dotfiles e o .vscode do ROS.
# Pode rodar quantas vezes quiser (idempotente).
#
# Variáveis opcionais:
#   ROS_WS_DIR=/caminho/do/ws   workspace onde o .vscode será copiado (padrão: ~/ros_ws)
#   SET_DEFAULT_SHELL=1         também troca o shell padrão do usuário para zsh (chsh)
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROS_WS_DIR="${ROS_WS_DIR:-$HOME/ros_ws}"

# sudo só quando for preciso: containers que rodam como root costumam nem ter o sudo instalado
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || { echo "[install] precisa rodar como root ou ter sudo instalado" >&2; exit 1; }
  SUDO="sudo"
fi

# ── 1. Pacotes de sistema ───────────────────────────────────────────────────────────────────────
# Confere ferramenta por ferramenta e instala só o que falta (antes, o passo inteiro era pulado se
# zsh e gdb já existissem, mesmo faltando jq ou o argcomplete).
declare -A NEED=(
  [zsh]=zsh
  [curl]=curl
  [git]=git
  [gdb]=gdb
  [jq]=jq
  [rosdep]=python3-rosdep
  [colcon]=python3-colcon-common-extensions
  [register-python-argcomplete]=python3-argcomplete
)
missing=()
for cmd in "${!NEED[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("${NEED[$cmd]}")
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "[install] faltando: ${missing[*]}"
  $SUDO apt-get update || echo "[install] AVISO: apt-get update falhou; tentando instalar mesmo assim"
  for pkg in "${missing[@]}"; do
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$pkg" \
      || echo "[install] AVISO: não consegui instalar '$pkg' (instale depois, se precisar)"
  done
fi

for essencial in zsh git curl; do
  command -v "$essencial" >/dev/null 2>&1 || { echo "[install] ERRO: '$essencial' é indispensável e não está instalado" >&2; exit 1; }
done

# ── 2. Oh My Zsh ────────────────────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "[install] instalando oh-my-zsh"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ── 3. Plugins e tema ───────────────────────────────────────────────────────────────────────────
clone_se_faltar() {   # clone_se_faltar <url> <destino>
  [ -d "$2" ] || git clone --depth=1 "$1" "$2"
}
clone_se_faltar https://github.com/zsh-users/zsh-autosuggestions        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_se_faltar https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_se_faltar https://github.com/romkatv/powerlevel10k.git            "$ZSH_CUSTOM/themes/powerlevel10k"

# ── 4. Links dos dotfiles ───────────────────────────────────────────────────────────────────────
# Se já existir um arquivo de verdade (não link) com conteúdo seu, guarda um backup antes de trocar.
# O modelo que o próprio oh-my-zsh acabou de criar não conta: pode ser trocado sem backup.
linkar() {   # linkar <origem> <destino>
  local origem="$1" destino="$2"
  if [ -e "$destino" ] && [ ! -L "$destino" ] && ! cmp -s "$destino" "$HOME/.oh-my-zsh/templates/zshrc.zsh-template"; then
    mv "$destino" "$destino.bak.$(date +%s)"
    echo "[install] backup de $destino"
  fi
  ln -sfn "$origem" "$destino"
  echo "[install] link: $destino -> $origem"
}
linkar "$DOTFILES_DIR/zshrc"     "$HOME/.zshrc"
linkar "$DOTFILES_DIR/p10k.zsh"  "$HOME/.p10k.zsh"

# ── 5. .vscode no workspace (cópia, nunca sobrescreve) ─────────────────────────────────────────
if [ -d "$ROS_WS_DIR" ]; then
  bash "$DOTFILES_DIR/inject-vscode.sh" "$ROS_WS_DIR"
else
  echo "[install] $ROS_WS_DIR não existe; pulei o .vscode (depois: inject_vscode /caminho/do/ws)"
fi

# ── 6. Shell padrão (opcional) ──────────────────────────────────────────────────────────────────
if [ "${SET_DEFAULT_SHELL:-0}" = "1" ]; then
  $SUDO chsh -s "$(command -v zsh)" "$(id -un)" || echo "[install] AVISO: chsh falhou; abra o zsh manualmente com: exec zsh"
fi

echo
echo "[install] pronto. Abra um terminal novo, ou rode: exec zsh"
