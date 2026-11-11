#!/usr/bin/env bash
# ros-env.sh — carrega o ambiente ROS 2 (sempre em bash, independe do shell do usuário).
# Uso:  . .vscode/ros-env.sh [underlay|full]
#   underlay -> só /opt/ros/<distro>              (use para COMPILAR)
#   full     -> underlay + install/ do workspace  (use para rodar, testar e depurar)

_mode="${1:-full}"
set --   # o setup.bash do ROS não deve enxergar argumentos
_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_ws="$(cd "$_here/.." && pwd)"
export ROS_DISTRO="${ROS_DISTRO:-jazzy}"

if [ "$_mode" = "underlay" ]; then
  # Se o terminal/VS Code já herdou o overlay (ex.: .zshrc faz source do install/),
  # limpa os prefixos antes: compilar com overlay carregado mistura versões dos pacotes.
  unset AMENT_PREFIX_PATH CMAKE_PREFIX_PATH COLCON_PREFIX_PATH AMENT_CURRENT_PREFIX
fi

if [ -f "/opt/ros/$ROS_DISTRO/setup.bash" ]; then
  # shellcheck disable=SC1090
  . "/opt/ros/$ROS_DISTRO/setup.bash"
else
  echo "[ros-env] /opt/ros/$ROS_DISTRO/setup.bash não encontrado" >&2
fi

if [ "$_mode" = "full" ] && [ -f "$_ws/install/setup.bash" ]; then
  # shellcheck disable=SC1091
  . "$_ws/install/setup.bash"
fi

unset _mode _here _ws
