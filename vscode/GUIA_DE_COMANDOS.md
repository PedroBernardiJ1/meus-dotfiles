# Comandos do workspace `ros_ws` — referência

Guia de tudo que existe em `.vscode/` e nos aliases do terminal: o quê, quando usar, e o comando
"de verdade" por trás de cada um. Salve isto em `ros_ws/.vscode/COMANDOS.md`.

## Como as camadas se encaixam

```
colcon / ros2 / rosdep     <- as ferramentas ROS de sempre
        ↑
   .vscode/ros.sh          <- script que chama a linha de cima com as flags certas
        ↑                     e o ambiente (ROS + workspace) já carregado
   aliases do ros.zsh      <- atalhos de terminal pro ros.sh (build, bringup, ros2 run...)
        ↑
  tasks.json / F5          <- botões do VS Code que chamam o ros.sh direto
```

Nada nas camadas de cima "esconde" nada: cada alias é uma linha de texto que expande pro comando
de baixo. Se algum dia um alias sumir ou você esquecer o que ele faz, `alias nome_do_alias` no
terminal mostra exatamente o que ele roda.

## Referência rápida

| Comando | Faz o quê | Quando usar | Manual (sem alias) |

* `build` --> Compila tudo em Debug + atualiza autocomplete | Toda vez que mexer em código | `colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` |

* `buildpkg <pacote...>` --> Compila só os pacotes listados, em Debug | Quando só mexeu num pacote — mais rápido | `colcon build --symlink-install --packages-select <pacote> --cmake-args -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` |

* `buildrelease` --> Compila tudo otimizado, sem símbolos de debug | Medir performance de verdade / preparar pro robô | `colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` |

* `ros2 run <pkg> <exe> [args]` --> Roda um nó | Testar manualmente | `source install/setup.zsh && ros2 run <pkg> <exe>` |

* `bringup <pkg> <arquivo> [args]` --> Roda um launch file | Subir vários nós de uma vez | `source install/setup.zsh && ros2 launch <pkg> <arquivo>` |

* `F5` (no VS Code) --> Roda com breakpoint | Precisa inspecionar variável / parar a execução | não existia |

* `runtests [--packages-select pkg]` --> Roda os testes automáticos | Opcional por enquanto, se ainda não escreveu teste nenhum | `colcon test && colcon test-result --verbose` |

* `installdeps` --> Instala dependências dos `package.xml` | Só quando adicionar uma dependência nova | `rosdep install --from-paths src --ignore-src -r -y` |

* `refresh` --> Recarrega o ambiente NESTE terminal | Só se usar `ros2 run`/`ros2 launch` direto (sem o wrapper) depois de compilar algo novo | `source install/setup.zsh` |

* `clean_auto` --> Apaga `build/install/log` (pede confirmação) | Raramente, se algo parecer corrompido | `rm -rf build install log` |

* `docker/scripts/build.sh` + `run.sh` --> Reconstrói a imagem e recria o container | Só quando editar o `robot.dockerfile` | não existia |

* `ros2 topic`, `ros2 node`, `ros2 param`, `ros2 bag` e qualquer outro subcomando continuam batendo direto no `ros2` de verdade — só `run` e `launch` passam pelo wrapper.

## Cada comando em detalhe

### `build` / `buildpkg` / `buildrelease` — compilar

```bash
build                        # tudo, Debug
buildpkg cylinder_volume     # só esse pacote, Debug
buildpkg pkg_a pkg_b         # mais de um pacote de uma vez, com Debug
buildrelease                 # tudo, otimizado
```

**Debug vs Release**: `Debug` compila com `-g -O0` (símbolos de depuração, sem otimização — o que
o `F5`/GDB precisa). `Release` compila com `-O3`, sem símbolos — mais rápido em tempo de execução,
mas sem `F5` funcionando direito depois. Só afeta C++; Python não é compilado.

`--symlink-install` já vem embutido em todo build — não precisa adicionar, e não tem
incompatibilidade nenhuma em usar.

Se precisar de uma flag do CMake que o `ros.sh` não previu (tipo `-DMINHA_OPCAO=ON`), rode o
colcon direto, com tudo dentro de um único `--cmake-args`, e depois atualize o autocomplete:

```bash
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DMINHA_OPCAO=ON
bash .vscode/ros.sh merge
```

### `ros2 run` / `bringup` — rodar

```bash
ros2 run cylinder_volume cylinder_volume
ros2 run cylinder_volume cylinder_volume --ros-args -p raio:=2.0
bringup cylinder_volume bringup.launch.py
bringup cylinder_volume bringup.launch.py use_sim_time:=true raio:=2.0
```
`ros2 run`/`ros2 launch` sempre carregam o `install/setup.bash` na hora, fresquinho — nunca
precisa dar `refresh` antes de usar esses dois.

### `runtests` — testes automáticos

```bash
runtests
bash .vscode/ros.sh test --packages-select cylinder_volume
```
Exige um `build`/`buildpkg` feito antes do pacote (senão dá "Has this package been built
before?"). Se você ainda não escreveu nenhum teste, o que ele roda são os verificadores de estilo
dos templates do `ros2 pkg create` — pode ignorar por enquanto, nada depende disso.

### `installdeps` — dependências

```bash
installdeps
```
Lê os `<depend>` de cada `package.xml` em `src/` e instala o que faltar. Só é preciso depois de
adicionar uma dependência nova — não faz parte do ciclo normal de build.

### `refresh` — recarregar o ambiente

```bash
refresh
```
Só necessário se você chamar `ros2 run`/`ros2 launch` **sem** passar pelo wrapper acima, num
terminal que já estava aberto antes do build mais recente. Abrir um terminal novo já resolve
sozinho (o `zshrc` carrega o `install/setup.zsh` toda vez que um terminal nasce).

### `clean_auto` — apagar tudo

```bash
clean_auto
```
Pede confirmação (`s`/`N`) antes de apagar `build/`, `install/` e `log/`. Depois, rode `build` de
novo do zero.

## Pelo VS Code, sem terminal

- `Ctrl+Shift+B` → mesma coisa que `build`
- `F5` → roda com breakpoint (preenche pacote/executável quando pedir)
- `Ctrl+Shift+P` → "Tasks: Run Task" → lista todas as tasks (build package, test, rosdep, run, launch, clean)

## Container Docker

```bash
docker/scripts/build.sh   # reconstrói a imagem — só depois de editar o robot.dockerfile
docker/scripts/run.sh     # recria o container (--rm: sempre nasce fresco, sem precisar apagar nada)
```
Isso não tem nada a ver com o ciclo de compilar/rodar código — só entra em cena quando o
`robot.dockerfile` muda.

## Nomeando um alias novo, sem se enrascar

Antes de criar um alias novo, rode `command -v nome_pensado` no terminal. Se vier vazio, é
seguro. Se vier algo, esse nome já é um comando/palavra reservada de verdade (ex.: `test`,
`rosdep`, `ros2`), e um alias com esse nome ia esconder o de verdade sempre que você digitasse.

## Problemas já vistos e a causa

| Sintoma | Causa | Solução |
|---|---|---|
| `compile_commands.json` com 0 bytes | Nunca rodou um build com `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON` | Rode `build` uma vez |
| `RUN rosdep init` falha no `docker build` com "already exists" | A imagem base `ros:jazzy` já vem com o rosdep inicializado | No Dockerfile: `RUN [ -e /etc/ros/rosdep/sources.list.d/20-default.list ] || rosdep init` |
| Extensões do VS Code pedindo pra instalar de novo toda vez | Container é `--rm` (efêmero); `~/.vscode-server` nasce vazio a cada container novo | Montar `~/.vscode-server` como volume no `run.sh` |
| F5 não abre / gdb não encontrado | `gdb` não estava na imagem | Adicionar `gdb` na Etapa 2 do Dockerfile e reconstruir |
