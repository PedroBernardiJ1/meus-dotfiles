# ros.zsh — aliases atalho pro .vscode/ros.sh. Sourceado pelo zshrc deste repositório de dotfiles.
# Não sourceia ROS/colcon/argcomplete aqui: seu zshrc já faz tudo isso antes deste arquivo ser
# carregado — repetir aqui só duplicaria o trabalho toda vez que um terminal abrir.
#
# Obs.: as tasks e o debug do VS Code NÃO usam este arquivo (rodam em bash via ros.sh) — editar ou
# apagar este arquivo não muda o comportamento de Ctrl+Shift+B / F5.

# Acha o workspace em que você está: sobe a partir da pasta atual até achar um .vscode/ros.sh (ou seja,
# um workspace onde o inject_vscode já foi rodado). Fora de qualquer workspace, tenta $ROS_WS_DIR
# (padrão ~/ros_ws). Assim os aliases funcionam em QUALQUER workspace do container, sem configurar nada.
_ros_ws() {
  local d="$PWD" padrao="${ROS_WS_DIR:-$HOME/ros_ws}"
  while [[ "$d" != "/" ]]; do
    [[ -f "$d/.vscode/ros.sh" ]] && { print -r -- "$d"; return 0; }
    d="${d:h}"
  done
  [[ -f "$padrao/.vscode/ros.sh" ]] && { print -r -- "$padrao"; return 0; }
  return 1
}

# Chama o ros.sh do workspace atual. Todos os aliases abaixo passam por aqui.
_ros_sh() {
  local ws
  ws="$(_ros_ws)" || { print -u2 "[ros] nenhum workspace com .vscode/ros.sh aqui — entre no workspace e rode: inject_vscode"; return 1; }
  bash "$ws/.vscode/ros.sh" "$@"
}

alias build="_ros_sh build Debug"               # compila em Debug (símbolos pro gdb) + atualiza o compile_commands.json
alias buildrelease="_ros_sh build Release"      # compila otimizado, sem símbolos — não dá pra usar com F5 depois
alias runtests="_ros_sh test"                   # roda os testes (colcon test) e mostra o resultado
alias installdeps="_ros_sh rosdep"              # instala as dependências que faltam, lendo os package.xml de src/
alias clean_auto="_ros_sh clean"                # apaga build/install/log (pede confirmação antes)
alias bringup="_ros_sh launch"                  # uso: bringup meu_pacote arquivo.launch.py [args]
buildpkg() { _ros_sh build Debug --packages-select "$@"; }   # compila só os pacotes selecionados em Debug — uso: buildpkg nome_do_pacote1 nome_do_pacote2

# Recarrega o ambiente NESTE terminal — só precisa se rodar "ros2 run" direto, sem passar pelo build/buildpkg.
# (função e não alias porque o "source" precisa rodar no shell atual)
refresh() {
  local ws
  ws="$(_ros_ws)" || { print -u2 "[ros] nenhum workspace com .vscode/ros.sh aqui"; return 1; }
  source "$ws/install/local_setup.zsh"
}

# "ros2 run" e "ros2 launch" continuam com a sintaxe de sempre — só passam pelo ros.sh por baixo,
# pra sempre carregar o install/setup.bash fresquinho. Qualquer outro subcomando (topic, node,
# param, bag...) vai direto pro ros2 de verdade, sem interferência. "command" abaixo é o jeito de
# dizer "ignore essa função, ache o programa de verdade" — evita a função chamar ela mesma.

ros2() {
  case "$1" in
    run|launch)
      if _ros_ws >/dev/null 2>&1; then _ros_sh "$@"; else command ros2 "$@"; fi ;;
    *) command ros2 "$@" ;;
  esac
}
