# ros.zsh — aliases atalho pro .vscode/ros.sh. Sourceado no fim do seu docker/config/zshrc.
# Não sourceia ROS/colcon/argcomplete aqui: seu zshrc já faz tudo isso antes deste arquivo ser
# carregado — repetir aqui só duplicaria o trabalho toda vez que um terminal abrir.
#
# Obs.: as tasks e o debug do VS Code NÃO usam este arquivo (rodam em bash via ros.sh) — editar ou
# apagar este arquivo não muda o comportamento de Ctrl+Shift+B / F5.

_ROS_WS="${${(%):-%x}:A:h:h}"            # pasta acima de .vscode

alias build="bash '$_ROS_WS/.vscode/ros.sh' build Debug"               # compila em Debug (símbolos pro gdb) + atualiza o compile_commands.json
alias buildrelease="bash '$_ROS_WS/.vscode/ros.sh' build Release"      # compila otimizado, sem símbolos — não dá pra usar com F5 depois
alias runtests="bash '$_ROS_WS/.vscode/ros.sh' test"                   # roda os testes (colcon test) e mostra o resultado
alias installdeps="bash '$_ROS_WS/.vscode/ros.sh' rosdep"              # instala as dependências que faltam, lendo os package.xml de src/
alias clean_auto="bash '$_ROS_WS/.vscode/ros.sh' clean"                # apaga build/install/log (pede confirmação antes)
alias refresh="source '$_ROS_WS/install/local_setup.zsh'"              # recarrega o ambiente NESTE terminal — só precisa se rodar "ros2 run" direto, sem passar pelo build/buildpkg
buildpkg() { bash "$_ROS_WS/.vscode/ros.sh" build Debug --packages-select "$@"; }   # compila só os pacotes selecionados em Debug — uso: buildpkg nome_do_pacote1 nome_do_pacote2

# "ros2 run" e "ros2 launch" continuam com a sintaxe de sempre — só passam pelo ros.sh por baixo,
# pra sempre carregar o install/setup.bash fresquinho. Qualquer outro subcomando (topic, node,
# param, bag...) vai direto pro ros2 de verdade, sem interferência. "command" abaixo é o jeito de
# dizer "ignore essa função, ache o programa de verdade" — evita a função chamar ela mesma.

ros2() {
  case "$1" in
    run|launch) bash "$_ROS_WS/.vscode/ros.sh" "$@" ;;
    *)          command ros2 "$@" ;;
  esac
}

alias bringup="bash '$_ROS_WS/.vscode/ros.sh' launch"   # uso: bringup meu_pacote arquivo.launch.py [args]
