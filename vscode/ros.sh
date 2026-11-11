#!/usr/bin/env bash
# ros.sh — comandos ROS 2 / colcon usados pelas tasks do VS Code e pelos aliases do zsh.
# Uso:  bash .vscode/ros.sh <comando> [args...]
#
#   build [Debug|Release|RelWithDebInfo] [args do colcon]   compila e atualiza o compile_commands
#   test [args do colcon]                                   colcon test + test-result
#   merge                                                   junta build/*/compile_commands.json
#   rosdep                                                  instala as dependências de src/ (auto-inicializa no 1º uso)
#   run <pacote> <executável> [args]                        ros2 run
#   launch <pacote> <arquivo> [args]                        ros2 launch
#   clean                                                   apaga build/ install/ log/ (pede confirmação)
#
# Roda sempre em bash e a partir da raiz do workspace, de qualquer diretório.

set -o pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS="$(cd "$HERE/.." && pwd)"
cd "$WS" || exit 1

CC_OUT=".vscode/compile_commands.json"

usage() { sed -n '2,12p' "${BASH_SOURCE[0]}"; }

# Junta os compile_commands de todos os pacotes. Só substitui o arquivo final se o jq der certo
# (o '>' direto no destino zerava o arquivo quando o jq falhava).
merge_cc() {
  if [ -z "$(find build -maxdepth 2 -name compile_commands.json -print -quit 2>/dev/null)" ]; then
    echo "[merge] nenhum compile_commands.json em build/ (workspace só com pacotes Python?)"
    return 0
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "[merge] 'jq' não encontrado. Instale com: sudo apt install jq" >&2
    return 1
  fi
  local tmp="$CC_OUT.tmp"
  if find build -maxdepth 2 -name compile_commands.json -print0 \
      | xargs -0 -r jq -s 'add | unique_by(.file)' > "$tmp"; then
    mv "$tmp" "$CC_OUT"
    echo "[merge] $(jq length "$CC_OUT") arquivos em $CC_OUT"
  else
    rm -f "$tmp"
    echo "[merge] falhou; o $CC_OUT anterior foi preservado" >&2
    return 1
  fi
}

build() {
  local type="${1:-Debug}"
  [ $# -gt 0 ] && shift
  # shellcheck disable=SC1091
  . "$HERE/ros-env.sh" underlay
  # Opções extras (--packages-select ...) vão ANTES de --cmake-args, que consome o que vier depois.
  colcon build --symlink-install --event-handlers console_direct+ "$@" \
    --cmake-args "-DCMAKE_BUILD_TYPE=$type" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  local rc=$?
  merge_cc
  local mrc=$?
  [ "$rc" -ne 0 ] && return "$rc"
  return "$mrc"
}

run_tests() {
  # shellcheck disable=SC1091
  . "$HERE/ros-env.sh" full
  colcon test --event-handlers console_direct+ "$@"
  colcon test-result --verbose
}

rosdep_install() {
  # shellcheck disable=SC1091
  . "$HERE/ros-env.sh" underlay
  # 1ª vez neste container (ou após rebuild da imagem): ainda não existe o índice do rosdep.
  # 'sudo rosdep init' é idempotente: se o Dockerfile já rodou isso no build, aqui só dá
  # "already exists" e o '|| true' ignora; se você esqueceu, ele resolve sozinho, sem travar.
  if [ ! -d "$HOME/.ros/rosdep/sources.cache" ]; then
    echo "[rosdep] cache não encontrado, inicializando (só acontece uma vez por container)..."
    sudo rosdep init 2>/dev/null || true
    rosdep update --rosdistro "$ROS_DISTRO"
  fi
  rosdep install --from-paths src --ignore-src -r -y --rosdistro "$ROS_DISTRO"
}

clean() {
  printf 'Apagar build/ install/ log/ em %s? [s/N] ' "$WS"
  read -r ans
  case "$ans" in
    s|S|y|Y) rm -rf build install log && echo "Limpo." ;;
    *) echo "Cancelado."; return 1 ;;
  esac
}

cmd="${1:-help}"
[ $# -gt 0 ] && shift
case "$cmd" in
  build)  build "$@" ;;
  test)   run_tests "$@" ;;
  merge)  merge_cc ;;
  rosdep) rosdep_install ;;
  clean)  clean ;;
  run)    # shellcheck disable=SC1091
          . "$HERE/ros-env.sh" full; exec ros2 run "$@" ;;
  launch) # shellcheck disable=SC1091
          . "$HERE/ros-env.sh" full; exec ros2 launch "$@" ;;
  help|-h|--help) usage ;;
  *) echo "Comando desconhecido: $cmd" >&2; usage; exit 1 ;;
esac
