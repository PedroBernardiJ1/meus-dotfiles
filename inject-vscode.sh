#!/usr/bin/env bash
# inject-vscode.sh — copia o modelo de .vscode (pasta vscode/ deste repositório) para um workspace ROS.
#
# Uso:  inject-vscode.sh [pasta_do_workspace]
#       Sem argumento: usa o workspace onde você está (sobe as pastas até achar uma com src/);
#       se não achar, usa $ROS_WS_DIR (padrão ~/ros_ws).
#
# Por que COPIA em vez de criar um link simbólico:
#   - o workspace normalmente é um bind mount do host; um link apontaria para um caminho que só existe
#     dentro do container, e apareceria quebrado no host;
#   - o build escreve .vscode/compile_commands.json e a extensão de ROS reescreve o settings.json —
#     com link, tudo isso cairia dentro do repositório de dotfiles.
#
# Nunca sobrescreve um arquivo que já existe. Para atualizar um arquivo do workspace com a versão
# do repositório: apague o arquivo no workspace e rode este script de novo.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DOTFILES_DIR/vscode"

# Raiz de um workspace colcon: pasta com src/ dentro. Pacotes também podem ter um src/ próprio
# (ex.: ws/src/meu_pkg/src), então ignora pastas que estão DENTRO de um src/ — sobe até a do workspace.
achar_workspace() {
  local d="$PWD"
  while [ "$d" != "/" ]; do
    if [ -d "$d/src" ] && [ "$(basename "$(dirname "$d")")" != "src" ]; then
      echo "$d"
      return 0
    fi
    d="$(dirname "$d")"
  done
  return 1
}

if [ -n "${1:-}" ]; then
  WS="$1"
elif WS="$(achar_workspace)"; then
  echo "[inject] workspace detectado: $WS"
else
  WS="${ROS_WS_DIR:-$HOME/ros_ws}"
  echo "[inject] nenhum workspace aqui; usando $WS"
fi

[ -d "$SRC" ] || { echo "[inject] pasta de modelo não encontrada: $SRC" >&2; exit 1; }
[ -d "$WS" ]  || { echo "[inject] workspace não existe: $WS" >&2; exit 1; }

mkdir -p "$WS/.vscode"

# distro e versão do Python deste container (os modelos vêm escritos para jazzy / python3.12)
DISTRO="${ROS_DISTRO:-}"
if [ -z "$DISTRO" ] && [ -d /opt/ros ]; then DISTRO="$(find /opt/ros -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort | head -n1)"; fi
PYV="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null || true)"

adaptar() {   # adaptar <arquivo> — só roda em arquivo recém copiado, nunca em um que já existia
  local arq="$1"
  if [ -n "$DISTRO" ] && [ "$DISTRO" != "jazzy" ]; then sed -i "s#/opt/ros/jazzy#/opt/ros/$DISTRO#g" "$arq"; fi
  if [ -n "$PYV" ] && [ "$PYV" != "3.12" ]; then sed -i "s#python3\.12#python$PYV#g" "$arq"; fi
}

copied=0
kept=0
for f in "$SRC"/*; do
  name="$(basename "$f")"
  case "$name" in compile_commands.json*) continue ;; esac   # é gerado pelo build, não é modelo
  if [ -e "$WS/.vscode/$name" ]; then
    kept=$((kept + 1))
    echo "[inject] mantido (já existe): $name"
  else
    cp "$f" "$WS/.vscode/$name"
    case "$name" in settings.json|c_cpp_properties.json) adaptar "$WS/.vscode/$name" ;; esac
    copied=$((copied + 1))
    echo "[inject] copiado: $name"
  fi
done

# o gdb-ros.sh é executado direto pelo VS Code (miDebuggerPath), então precisa do bit de execução
chmod +x "$WS/.vscode/"*.sh 2>/dev/null || true

echo "[inject] $copied copiado(s), $kept mantido(s) em $WS/.vscode"

# Esconde o .vscode do Git só neste clone (sem mexer em .gitignore). Só funciona se o .git estiver
# visível daqui — num container que monta apenas o ros_ws, ele não está.
if GIT_ABS="$(git -C "$WS" rev-parse --absolute-git-dir 2>/dev/null)"; then
  mkdir -p "$GIT_ABS/info"
  grep -qxF ".vscode/" "$GIT_ABS/info/exclude" 2>/dev/null || echo ".vscode/" >> "$GIT_ABS/info/exclude"
  echo "[inject] .vscode/ adicionado ao exclude local do Git"
else
  echo "[inject] (.git não visível daqui; se o workspace é versionado no host, rode LÁ: echo '.vscode/' >> .git/info/exclude)"
fi
