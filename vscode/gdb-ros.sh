#!/usr/bin/env bash
# gdb-ros.sh — wrapper do GDB para o launch.json (miDebuggerPath).
# O cppdbg não faz source de nada: sem isto o nó não acha as .so do ROS nem as do seu workspace.
# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/ros-env.sh" full
# Evita o prompt "Enable debuginfod?" do gdb, que trava a sessão MI do VS Code.
unset DEBUGINFOD_URLS
if ! command -v gdb >/dev/null 2>&1; then
  echo "[gdb-ros] 'gdb' não está instalado nesta imagem." >&2
  echo "[gdb-ros] adicione 'gdb' à Etapa 2 do robot.dockerfile e rode docker/scripts/build.sh de novo." >&2
  exit 127
fi
exec gdb "$@"
