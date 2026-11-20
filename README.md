# meus-dotfiles

Shell (zsh + oh-my-zsh + powerlevel10k) e `.vscode` de ROS 2 para qualquer container.

## Container novo

```bash
git clone https://github.com/PedroBernardiJ1/meus-dotfiles.git ~/meus-dotfiles
~/meus-dotfiles/install.sh
exec zsh
```

Use o endereço **HTTPS** (acima): um container novo não tem sua chave SSH. Se o repositório for
privado, o clone pede um token; a alternativa é montar a pasta do host no container
(`-v ~/meus-dotfiles:/home/host/meus-dotfiles`) e rodar o `install.sh` de lá.

Variáveis opcionais: `ROS_WS_DIR=/outro/ws` (padrão `~/ros_ws`) e `SET_DEFAULT_SHELL=1` (troca o shell padrão).

## Repositório / workspace novo

Dentro do workspace (a pasta que tem `src/`), uma vez:

```bash
inject_vscode
```

Ele acha o workspace sozinho (mesmo se você estiver dentro de um pacote), copia o `.vscode` sem
sobrescrever nada e ajusta a distro e a versão do Python do container. Depois disso, `build`,
`buildpkg`, `bringup`, `ros2 run`... funcionam nesse workspace — os aliases usam o workspace da
pasta onde você está, então vários workspaces no mesmo container não atrapalham.

No VS Code, abra a pasta do workspace (a que tem o `.vscode`), não a raiz do repositório.

| O quê | Automático? |
|---|---|
| Shell, aliases e autocomplete em **container novo** | Não: um comando por container (clone + `install.sh`), porque o container é descartado ao sair |
| Aliases em **qualquer workspace** do container | Sim: vêm da pasta onde você está |
| `.vscode` em **repositório/workspace novo** | Não, de propósito: rode `inject_vscode` (não mexo no seu repositório sem você pedir) |
| Distro e versão do Python nos modelos | Sim, na hora da cópia |
| Interfaces customizadas no Pylance | Não: dependem do projeto (veja o comentário no `settings.json`) |

## O que cada coisa faz

| Arquivo | Função |
|---|---|
| `install.sh` | Instala o que faltar (zsh, gdb, jq, argcomplete...), oh-my-zsh, plugins e tema; linka `zshrc` e `p10k.zsh`; copia o `.vscode` para o workspace. Pode rodar de novo sem problema. |
| `zshrc` / `p10k.zsh` | Viram `~/.zshrc` e `~/.p10k.zsh` (links: editar aqui vale na hora). |
| `inject-vscode.sh` | Copia `vscode/` para `<workspace>/.vscode`, sem sobrescrever nada que já exista. No terminal: `inject_vscode [pasta]`. |
| `vscode/` | Modelo do `.vscode` (tasks, launch, scripts `ros*.sh`, settings genéricos) e `ros.zsh` (aliases). |

## Por que o `.vscode` é copiado e não linkado

O workspace costuma ser um bind mount do host (um link apontaria para um caminho que só existe no
container), e o build/extensões escrevem dentro de `.vscode` (`compile_commands.json`, `settings.json`) —
com link, isso sujaria este repositório. Para atualizar um arquivo do workspace com a versão daqui:
apague o arquivo no workspace e rode `inject_vscode` de novo.
