# Roteiro de Execução em Cascata: Debian-to-BerryCore (QNX Neutrino / BlackBerry Q5)

> **Modo de Operação:** Execução Sequencial Estrita em Cascata (*Waterfall + DAG*) com Portões de Verificação (*Quality Gates*).
> **Raiz do Repositório:** `/home/antigravity/Estagiarius/teste1` (estrutura diretamente na raiz de `teste1`).
> **Alvo:** BlackBerry Q5 — `armv7le` (`arm-blackberry-qnx8eabi`, ARM 32-bit `softfp`), QNX Neutrino 6.5/6.6, BlackBerry OS 10.
> **Prefixo Imutável no Dispositivo (`PREFIX`):** `/accounts/1000/shared/misc/berrycore`

---

## 0. Contrato de Execução e Protocolo do Agente

### 0.1 Convenção de Marcação de Tarefas
O agente deve atualizar este documento em tempo real conforme avança pela cascata:
- `[ ]` **Pendente** — ainda não iniciado.
- `[/]` **Em Execução** — etapa atualmente em andamento (apenas 1 item ativo por vez).
- `[x]` **Concluído** — implementado e validado pelo respectivo portão (*Gate*).
- `[!]` **Bloqueado (`BLOCKED`)** — falhou após 3 ciclos de correção (permitido apenas em pacotes não críticos das Camadas 2, 3 e 4, com log salvo em `logs/<pacote>-error.log` e registrado em `dist/manifest.json`).

### 0.2 Regras Invioláveis (Hard Constraints)
1. **Isolamento Total:** Toda compilação e instalação de ferramentas/bibliotecas ocorre exclusivamente dentro do contêiner Docker Linux `x86_64`. Nunca instalar dependências de build ou toolchains no sistema hospedeiro.
2. **Zero Host Leakage:** Nenhum binário ELF, biblioteca `.so`, arquivo `.pc` ou script final pode conter caminhos da máquina de build (`/usr/lib`, `/home/...`, `$STAGING`). Todos os caminhos embutidos devem apontar exclusivamente para `$PREFIX` (`/accounts/1000/shared/misc/berrycore`).
3. **Validação ELF Obrigatória:** Nenhum pacote pode ser marcado como `[x]` sem aprovação integral em `scripts/verify-elf.sh`.
4. **Ordem Estrita de Cascata:** É proibido avançar para a Fase `N+1` ou Camada `L+1` antes que o **Gate** da etapa atual esteja 100% aprovado.
5. **Isolamento de Falhas (Máximo 3 Tentativas):** Se um pacote falhar após 3 ciclos de diagnóstico/patch, registrar as últimas evidências em `logs/<pacote>-error.log`, marcá-lo como `[!]` (`BLOCKED`) neste roteiro e em `dist/manifest.json`, pular seus dependentes diretos e prosseguir com os pacotes independentes.
6. **Reprodutibilidade Determinística:** Todo patch aplicado em código-fonte deve ser versionado em `patches/<pacote>/*.patch` (nunca manter edições manuais efêmeras em `/tmp`).

### 0.3 Constantes Globais do Pipeline
| Variável | Valor Imutável |
| :--- | :--- |
| `REPO_ROOT` | `/home/antigravity/Estagiarius/teste1` |
| `TARGET` | `arm-blackberry-qnx8eabi` |
| `PREFIX` | `/accounts/1000/shared/misc/berrycore` |
| `STAGING` | `/workspace/staging` |
| `SYSROOT_PREFIX` | `/workspace/staging/accounts/1000/shared/misc/berrycore` |
| `TOOLCHAIN_DIR` | `/opt/bb10-gcc9` |
| `MAX_RETRIES` | `3` |

### 0.4 Diagrama de Cascata e DAG de Dependências

```mermaid
flowchart TD
    E0["Etapa 0: Inicialização da Estrutura do Repositório"] --> G_INIT{"Gate Init: Árvore Git pronta"}
    G_INIT --> F0["Fase 0: Infraestrutura Docker + Toolchain GCC 9.3 QNX"]
    F0 --> G0{"Gate 0: docker build=0 + hello.c ARM QNX ELF OK"}
    G0 --> F1["Fase 1: Motor de Build e Validação (scripts/)"]
    F1 --> G1{"Gate 1: env-cross, build-pkg, verify-elf e run-all validados"}
    G1 --> C0["Fase 2 / Camada 0: Bibliotecas de Fundação (00..08)"]
    C0 --> GC0{"Gate Camada 0: 100% SUCCESS obrigatório"}
    GC0 --> C1["Fase 2 / Camada 1: Criptografia e Rede Moderna (10..15)"]
    C1 --> GC1{"Gate Camada 1: 100% SUCCESS obrigatório"}
    GC1 --> C2["Fase 2 / Camada 2: Compressão e Núcleo POSIX/GNU (20..36)"]
    C2 --> GC2{"Gate Camada 2: ELF OK + falhas isoladas"}
    GC2 --> C3["Fase 2 / Camada 3: Shell, Multiplexador e Editores Q5 (40..47)"]
    C3 --> GC3{"Gate Camada 3: ELF OK + falhas isoladas"}
    GC3 --> C4["Fase 2 / Camada 4: Interpretadores e Clientes Avançados (50..55)"]
    C4 --> GC4{"Gate Camada 4: ELF OK + falhas isoladas"}
    GC4 --> F4["Fase 4: Strip, env.sh, Empacotamento .zip, SHA256, manifest.json e BUILD_REPORT.md"]
    F4 --> G4{"Gate 4: Artefatos e metadados íntegros"}
    G4 --> F5["Fase 5: Auditoria Global (Definition of Done)"]
    F5 --> DONE(["ENTREGA CONCLUÍDA"])
```

### 0.5 Painel de Rastreamento de Cascata

| Etapa | Descrição | Bloqueante? | Status |
| :--- | :--- | :---: | :---: |
| Etapa 0 | Estrutura do Repositório (raiz de `teste1`) | Sim | `[x]` |
| Fase 0 | Docker + Toolchain GCC 9.3 QNX | Sim (Gate 0) | `[x]` |
| Fase 1 | Motor de Build e Validação (`scripts/`) | Sim (Gate 1) | `[x]` |
| Fase 2 — Camada 0 | Bibliotecas de Fundação (9 pacotes) | Sim (100% obrigatório) | `[x]` |
| Fase 2 — Camada 1 | Pilha Criptográfica e Rede (6 pacotes) | Sim (100% obrigatórios) | `[x]` |
| Fase 2 — Camada 2 | Compressão e Núcleo POSIX/GNU (17 pacotes) | Parcial (isolamento) | `[x]` (12/17 SUCCESS, 5 BLOCKED) |
| Fase 2 — Camada 3 | Shell, Multiplexador e Teclado Q5 (8 pacotes) | Parcial (isolamento) | `[x]` (3/8 SUCCESS, 5 BLOCKED) |
| Fase 2 — Camada 4 | Interpretadores e Clientes Avançados (6 pacotes) | Parcial (isolamento) | `[x]` (3/6 SUCCESS, 3 BLOCKED) |
| Fase 4 | Empacotamento, Metadados e Relatório | Sim (Gate 4) | `[x]` |
| Fase 5 | Auditoria Final (Definition of Done) | Sim (Gate Global) | `[x]` |

---

## Etapa 0 — Inicialização da Arquitetura de Diretórios

**Pré-requisito:** Repositório Git inicializado na raiz de `teste1`.

### Checklist de Tarefas
- [x] **0.1** Criar a árvore completa de diretórios na raiz de `teste1`:
  - `docker/`
  - `scripts/`
  - `recipes/`
  - `patches/`
  - `downloads/`
  - `staging/`
  - `dist/packages/`
  - `logs/`
- [x] **0.2** Criar `.gitignore` preservando estrutura de diretórios via `.gitkeep` e ignorando binários temporários de build (`downloads/*`, `staging/*`, `dist/*.zip`, `dist/packages/*`, `logs/*.log`) enquanto mantém `patches/`, `recipes/`, `scripts/`, `docker/`, `ROTEIRO_CASCATA.md` e `BUILD_REPORT.md` versionados.
- [x] **0.3** Regra definida para permissões de execução (`chmod +x`) em todos os scripts a serem criados em `scripts/` (Fase 1).

### Gate Init (Critério de Passagem)
- [x] **GATE-INIT:** Todos os diretórios obrigatórios existem na raiz de `teste1`, `.gitignore` e `.gitkeep` configurados, `git status` limpo de temporários e Docker daemon verificado (`Docker 29.10.0` ativo).

---

## Fase 0 — Infraestrutura e Toolchain (Docker)

**Pré-requisito:** `GATE-INIT` aprovado.

### Checklist de Tarefas
- [x] **F0.1** Criar `docker/Dockerfile` baseado em `debian:bookworm-slim` (`--platform=linux/amd64`).
- [x] **F0.2** Configurar instalação de todas as dependências de host via `apt-get` (com limpeza de cache `/var/lib/apt/lists/*`):
  - `build-essential`, `cmake`, `autoconf`, `automake`, `libtool`, `pkg-config`, `bison`, `flex`, `gawk`, `m4`, `patch`, `git`, `git-lfs`, `curl`, `wget`, `ca-certificates`, `unzip`, `zip`, `xz-utils`, `python3`, `perl`, `file`, `binutils`, `texinfo`, `jq`, além de multiarch `i386` (`libc6:i386`, `libstdc++6:i386`, `zlib1g:i386`) para os binários 32-bit da toolchain.
- [x] **F0.3** Configurar download direto via GitHub LFS media (`media.githubusercontent.com`) e extração da toolchain comunitária BerryCore GCC 9.3.0 (`toolchain/gcc-9.3.0-qnx8.tar.gz`) de `https://github.com/sw7ft/BerryCore` para `/opt/bb10-gcc9`, adicionando `/opt/bb10-gcc9/bin` ao `PATH` do contêiner.
- [x] **F0.4** Configurar atualização dos arquivos globais `/usr/share/misc/config.sub` e `/usr/share/misc/config.guess` a partir do repositório oficial GNU `config` para reconhecimento do alvo `arm-blackberry-qnx8eabi` / QNX.
- [x] **F0.5** Definir `WORKDIR /workspace` e variáveis `TOOLCHAIN_DIR`, `QNX_HOST`, `QNX_TARGET` e `QNX_PREBUILT_*` no `docker/Dockerfile`.
- [x] **F0.6** Construir a imagem Docker do zero (`bb10-berrycore-builder:latest`, log em `logs/phase0-docker-build.log`, exit code `0`).

### Gate 0 — Critério de Aceitação (Bloqueante)
Executado dentro do contêiner recém-construído:
- [x] **GATE-0.1** `docker build` retornou código de saída `0` sem intervenção manual.
- [x] **GATE-0.2** `arm-blackberry-qnx8eabi-gcc --version` executa e reporta `arm-blackberry-qnx8eabi-gcc (GCC) 9.3.0`.
- [x] **GATE-0.3** Compilado `hello.c` mínimo (usando `<stdio.h>` e `<sys/socket.h>`, linkando com `-lsocket`) via `arm-blackberry-qnx8eabi-gcc`.
- [x] **GATE-0.4** Saída de `file hello` contém `ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /usr/lib/ldqnx.so.2`.
- [x] **GATE-0.5** Saída de `readelf -d hello` lista **apenas** bibliotecas nativas do QNX (`libsocket.so.3`, `libc.so.3`) e **nenhuma** referência a `libc.so.6` ou `ld-linux`.

---

## Fase 1 — Motor de Build e Validação Automatizada (`scripts/`)

**Pré-requisito:** `GATE-0` 100% aprovado.

### Checklist de Tarefas
- [x] **F1.1** Implementar `scripts/env-cross.sh` exportando obrigatoriamente:
  - `TARGET="arm-blackberry-qnx8eabi"`
  - `PREFIX="/accounts/1000/shared/misc/berrycore"`
  - `STAGING="/workspace/staging"`
  - `SYSROOT_PREFIX="${STAGING}${PREFIX}"`
  - `CC`, `CXX`, `AR`, `AS`, `LD`, `RANLIB`, `STRIP`, `NM`, `READELF` apontando para `${TOOLCHAIN_DIR}/bin/arm-blackberry-qnx8eabi-*`
  - `HOSTCC="gcc"` e `HOSTCXX="g++"` (para ferramentas auxiliares no host)
  - `PKG_CONFIG_LIBDIR="${SYSROOT_PREFIX}/lib/pkgconfig:${SYSROOT_PREFIX}/share/pkgconfig"`
  - `PKG_CONFIG_SYSROOT_DIR="${STAGING}"` e `unset PKG_CONFIG_PATH`
  - `CFLAGS="-O2 -pipe -I${SYSROOT_PREFIX}/include"`
  - `CXXFLAGS="-O2 -pipe -I${SYSROOT_PREFIX}/include"`
  - `CPPFLAGS="-I${SYSROOT_PREFIX}/include"`
  - `LDFLAGS="-L${SYSROOT_PREFIX}/lib -Wl,-rpath,${PREFIX}/lib -lsocket"`
- [x] **F1.2** Implementar `scripts/verify-elf.sh` recebendo um arquivo ou diretório e executando as 4 validações em todos os arquivos ELF encontrados:
  1. **Arquitetura:** confirmar `ELF 32-bit LSB` e `ARM` via `file` / `readelf -h` (falhar imediatamente se `x86-64` ou outra arquitetura).
  2. **Contaminação Linux:** confirmar que `readelf -d` não contém `libc.so.6`, `ld-linux`, `libpthread.so.0` ou `libdl.so.2`.
  3. **Resolução de Dependências (`NEEDED`):** confirmar que toda biblioteca listada em `NEEDED` existe no sysroot da toolchain QNX (`/opt/bb10-gcc9/...`) ou em `${SYSROOT_PREFIX}/lib`.
  4. **Proibição de Host Leakage:** confirmar que `RPATH`/`RUNPATH` não contêm `$STAGING`, `/usr/lib` ou `/home/`.
- [x] **F1.3** Implementar `scripts/build-pkg.sh` recebendo `recipes/<id>-<pkg>.sh` e executando o ciclo completo:
  1. Carregar `scripts/env-cross.sh` e a receita alvo (`PKG_NAME`, `PKG_VER`, `PKG_URL`, `PKG_SHA256`, `PKG_DEPS`, `build()`, `install_staging()`).
  2. Baixar tarball para `downloads/` (reutilizando cache local se existir) e validar integridade via `sha256sum`.
  3. Limpar e extrair em `/tmp/build/${PKG_NAME}`.
  4. Substituir preventivamente qualquer `config.sub` e `config.guess` encontrado na árvore extraída pelos arquivos atualizados de `/usr/share/misc/`.
  5. Aplicar em ordem alfabética todos os patches em `patches/${PKG_NAME}/*.patch`.
  6. Registrar snapshot dos arquivos em `${SYSROOT_PREFIX}` antes da instalação (para rastrear artefatos do pacote individual e gerar o `.zip` modular).
  7. Executar `build()` e `install_staging()` redirecionando stdout/stderr para `logs/${PKG_NAME}.log`.
  8. Auditar novos arquivos contra *host leakage* (scripts, arquivos `.pc` e `.la` sem caminhos `$STAGING` residuais).
  9. Executar obrigatoriamente `scripts/verify-elf.sh` sobre todos os novos binários e `.so` instalados pelo pacote.
  10. Gravar metadados parciais do pacote (lista de arquivos, binários, `NEEDED`, tamanho em KB, status `SUCCESS`).
- [x] **F1.4** Implementar `scripts/run-all.sh`:
  - Iterar receitas em `recipes/[0-9][0-9]-*.sh` em ordem numérica estrita (DAG).
  - Verificar se todas as dependências em `PKG_DEPS` possuem status `SUCCESS`; se alguma dependência estiver `BLOCKED`, marcar o pacote dependente como `BLOCKED` (motivo: dependência bloqueada) sem interromper pacotes independentes.
  - Consolidar o estado em `dist/manifest.json`.
  - Falhar com exit code != 0 se qualquer pacote obrigatório da Camada 0 ou Camada 1 não atingir `SUCCESS`.
- [x] **F1.5** Implementar `scripts/package.sh` completo (strip, pós-strip `verify-elf.sh`, `env.sh`, zips modulares e consolidado, `SHA256SUMS`, `manifest.json` e `BUILD_REPORT.md`, pronto para execução na Fase 4).

### Gate 1 — Critério de Aceitação (Bloqueante)
- [x] **GATE-1.1** `bash -n scripts/*.sh` retorna `0` (zero erros de sintaxe).
- [x] **GATE-1.2** Teste positivo de `scripts/verify-elf.sh`: retornou `0` (`analisados=1 aprovados=1 falhas=0`) sobre o binário `hello` (ARM QNX) compilado no Gate 0.
- [x] **GATE-1.3** Teste negativo de `scripts/verify-elf.sh`: retorna código diferente de `0` ao analisar `/bin/ls` (`x86_64`/glibc), reportando `[ARCH]` e `[LINUX-LEAK]`.
- [x] **GATE-1.4** `scripts/env-cross.sh` isola `pkg-config` (`PKG_CONFIG_PATH` limpo, `pkg-config --list-all` = 0 itens do host) e `scripts/build-pkg.sh` rejeita execução fora do contêiner Docker.

---

## Fase 2 — Execução do DAG de Compilação (Camadas 0 a 4)

> **Regra de Execução por Pacote:** Para cada item abaixo, o agente deve:
> 1. Criar a receita `recipes/<id>-<pkg>.sh` (com URL upstream oficial, SHA256 verificado, `PKG_DEPS`, `build()` e `install_staging()`).
> 2. Executar `scripts/build-pkg.sh recipes/<id>-<pkg>.sh` dentro do contêiner Docker.
> 3. Em caso de falha, acionar imediatamente o **Protocolo Determinístico de Autocorreção (Fase 3)** — máximo 3 tentativas.
> 4. Marcar `[x]` somente após `scripts/verify-elf.sh` retornar `0`.

---

### Camada 0 — Bibliotecas de Fundação (OBRIGATÓRIA: 100% SUCCESS)

**Pré-requisito:** `GATE-1` aprovado.

- [x] **C0.0** `recipes/00-zlib.sh` — `zlib` `1.4` (`SUCCESS`, 266 KB)
  - *Dependências:* nenhuma.
  - *Notas técnicas:* gerar `libz.so` e `libz.a` em `${SYSROOT_PREFIX}/lib` e cabeçalhos em `${SYSROOT_PREFIX}/include`; usar `CHOST=${TARGET}`.
- [x] **C0.1** `recipes/01-ncurses.sh` — `ncurses` `6.5` + `ncurses-bin` (`SUCCESS`, 4781 KB; patches `01-qnx8eabi-shlib.patch`, `02-qnx-wcwidth.patch`)
  - *Dependências:* nenhuma.
  - *Notas técnicas:* compilar `tic` nativo no host primeiro (se necessário para gerar base `terminfo` sem `Exec format error`); habilitar wide-char (`--enable-widec`), `--with-shared`, `--with-termlib` (ou links de compatibilidade `libncurses.so` -> `libncursesw.so`, `libtermcap.so` -> `libncursesw.so`), gerar `tput`, `clear`, `infocmp` e base `terminfo` em `${PREFIX}/share/terminfo`.
- [x] **C0.2** `recipes/02-readline.sh` — `readline` `8.2.13` (`SUCCESS`, 1324 KB; patch `01-qnx-sigset.patch`)
  - *Dependências:* `ncurses`.
  - *Notas técnicas:* passar `--with-curses` e `SHLIB_LIBS="-lncursesw"` (ou `-ltinfow`), pré-definir cache cross `bash_cv_wcwidth_broken=no`.
- [x] **C0.3** `recipes/03-libevent.sh` — `libevent` `2.1.13-stable` (`SUCCESS`, 1680 KB; patches `01-qnx-sa-restart.patch`, `02-qnx-syslog.patch`)
  - *Dependências:* nenhuma (base para `tmux`; compilar sem OpenSSL nesta camada ou habilitar suporte básico de eventos via `select`/`poll`).
  - *Notas técnicas:* desabilitar `epoll` Linux (`--disable-epoll` se disponível ou via `#ifdef __QNXNTO__`).
- [x] **C0.4** `recipes/04-pcre2.sh` — `pcre2` `10.49` (`SUCCESS`, 3900 KB)
  - *Dependências:* `zlib`.
  - *Notas técnicas:* habilitar `--enable-pcre2-8`, `--enable-unicode`, desabilitar JIT caso incompatível com QNX ARMv7 softfp.
- [x] **C0.5** `recipes/05-libffi.sh` — `libffi` `3.8.1` (`SUCCESS`, 71 KB)
  - *Dependências:* nenhuma.
  - *Notas técnicas:* validar suporte ARM EABI (`softfp`); base obrigatória para `python3`.
- [x] **C0.6** `recipes/06-expat.sh` — `expat` `2.10.0` (`SUCCESS`, 541 KB; `-DXML_DEV_URANDOM`)
  - *Dependências:* nenhuma.
  - *Notas técnicas:* base obrigatória para módulo XML do `python3`.
- [x] **C0.7** `recipes/07-sqlite3.sh` — `sqlite3` `3.47.2` (`SUCCESS`, 3898 KB)
  - *Dependências:* `zlib`, `ncurses`, `readline`.
  - *Notas técnicas:* usar tarball *autoconf amalgamation* em C puro; gerar `libsqlite3.so` e CLI `sqlite3`.
- [x] **C0.8** `recipes/08-ca-certificates.sh` — `ca-certificates` `2025-10` (`SUCCESS`, 196 KB)
  - *Dependências:* nenhuma.
  - *Notas técnicas:* empacotar bundle atualizado de certificados raiz (Mozilla/curl `cacert.pem` ou Debian `ca-certificates`) em `${SYSROOT_PREFIX}/etc/ssl/certs/ca-certificates.crt`.

#### Gate Camada 0 (Bloqueante — 100% Obrigatório)
- [x] **GATE-C0.1** Todos os 9 pacotes (`00` a `08`) possuem status `SUCCESS` (zero `BLOCKED`).
- [x] **GATE-C0.2** `scripts/verify-elf.sh ${SYSROOT_PREFIX}` retornou `0` erros (`analisados=27 aprovados=27 falhas=0`).
- [x] **GATE-C0.3** `${SYSROOT_PREFIX}/etc/ssl/certs/ca-certificates.crt` existe e não está vazio (`196K`).

---

### Camada 1 — Pilha Criptográfica e Rede Moderna (PRIORIDADE CRÍTICA — 100% SUCCESS)

**Pré-requisito:** `GATE-C0` 100% aprovado.

- [x] **C1.0** `recipes/10-openssl.sh` — `openssl` `3.5.9` (3.x LTS) (`SUCCESS`, 13008 KB; patch `01-qnx-no-syslog.patch`)
  - *Dependências:* `zlib`, `ca-certificates`.
  - *Notas técnicas:* configurar com `--prefix=${PREFIX}`, `--openssldir=${PREFIX}/etc/ssl`, alvo QNX ou `linux-generic32` adaptado (sem `linux/random.h`/dependências Linux, sem `async`/dso incompatível se falhar, linkando `-lsocket`, `no-tests`, `shared`, `zlib`). Instalar via `make DESTDIR=${STAGING} install_sw install_ssldirs`.
- [x] **C1.1** `recipes/11-nghttp2.sh` — `nghttp2` `1.71.0` (`SUCCESS`, 742 KB)
  - *Dependências:* `zlib`, `openssl`.
  - *Notas técnicas:* compilar apenas biblioteca (`--enable-lib-only`) para fornecer HTTP/2 ao `curl`.
- [x] **C1.2** `recipes/12-curl.sh` — `curl` `8.23.0` (`SUCCESS`, 3804 KB)
  - *Dependências:* `openssl`, `zlib`, `ca-certificates`, `nghttp2` (opcional se disponível).
  - *Notas técnicas:* passar `--with-openssl=${SYSROOT_PREFIX}`, `--with-zlib=${SYSROOT_PREFIX}`, `--with-ca-bundle=${PREFIX}/etc/ssl/certs/ca-certificates.crt`, `--without-libpsl` (se não compilado).
- [x] **C1.3** `recipes/13-wget.sh` — `wget` `1.25.0` (`SUCCESS`, 765 KB; patch `01-qnx-pselect-time.patch`)
  - *Dependências:* `openssl`, `zlib`, `pcre2`, `ca-certificates`.
  - *Notas técnicas:* `--with-ssl=openssl`, `--with-openssl=yes`, `--disable-iri`, `--disable-ntlm`, `--disable-rpath`, `--without-libiconv-prefix`.
- [x] **C1.4** `recipes/14-openssh-client.sh` — `openssh-client` `10.6p2` (`SUCCESS`, 1891 KB; patch `01-qnx-syslog.patch`)
  - *Dependências:* `openssl`, `zlib`.
  - *Notas técnicas:* gerar e instalar `ssh`, `scp`, `sftp`, `ssh-keygen`, `ssh-agent` (`--with-ssl-dir=${SYSROOT_PREFIX}`, `--with-zlib=${SYSROOT_PREFIX}`, `--disable-strip` para evitar strip com binário host).
- [x] **C1.5** `recipes/15-rsync.sh` — `rsync` `3.5.2` (`SUCCESS`, 774 KB; patches `01-qnx-syslog.patch`, `02-qnx-at-removedir.patch`)
  - *Dependências:* `zlib`, `openssl`.
  - *Notas técnicas:* `--disable-xxhash --disable-zstd --disable-lz4 --disable-idn --disable-iconv`, `-DMAKEDEV_TAKES_3_ARGS`, `--enable-openssl`.

#### Gate Camada 1 (Bloqueante — 100% Obrigatório nos Pacotes Críticos)
- [x] **GATE-C1.1** `openssl`, `nghttp2`, `curl`, `wget`, `openssh-client` e `rsync` possuem status `SUCCESS` (100% obrigatório conforme Definition of Done).
- [x] **GATE-C1.2** `scripts/verify-elf.sh ${SYSROOT_PREFIX}` retornou `0` erros em todos os binários e bibliotecas `.so` (`analisados=40 aprovados=40 falhas=0`).
- [x] **GATE-C1.3** Verificação de strings confirmou que `libcurl.so` referencia `/accounts/1000/shared/misc/berrycore/etc/ssl/certs/ca-certificates.crt` e `libcrypto.so.3` define `OPENSSLDIR: "/accounts/1000/shared/misc/berrycore/etc/ssl"` sem caminhos de runtime apontando para `$STAGING`.

---

### Camada 2 — Compressão e Núcleo POSIX/GNU

**Pré-requisito:** `GATE-C1` 100% aprovado.

- [x] **C2.0** `recipes/20-bzip2.sh` — `bzip2` `1.0.8` (`SUCCESS`, 198 KB)
- [x] **C2.1** `recipes/21-xz.sh` — `xz-utils` `5.8.4` (`SUCCESS`, 813 KB)
- [x] **C2.2** `recipes/22-gzip.sh` — `gzip` `1.13` (`SUCCESS`, 214 KB)
- [!] **C2.3** `recipes/23-tar.sh` — `tar` `1.35` (`BLOCKED` após 3 ciclos — `logs/tar-error.log`; patch `01-qnx-makedev.patch`)
- [x] **C2.4** `recipes/24-zip.sh` — `zip` `3.0` (`SUCCESS`, 384 KB)
- [x] **C2.5** `recipes/25-unzip.sh` — `unzip` `6.0` (`SUCCESS`, 185 KB)
- [!] **C2.6** `recipes/26-diffutils.sh` — `diffutils` `3.10` (`BLOCKED` após 3 ciclos — `logs/diffutils-error.log`)
- [x] **C2.7** `recipes/27-patch.sh` — `patch` `2.7.6` (`SUCCESS`, 210 KB)
- [x] **C2.8** `recipes/28-sed.sh` — `sed` `4.9` (`SUCCESS`, 352 KB; patch `01-qnx-pselect-time.patch`)
- [x] **C2.9** `recipes/29-mawk.sh` — `mawk` `1.3.4-20250131` (`SUCCESS`, 234 KB)
- [!] **C2.10** `recipes/30-grep.sh` — `grep` `3.11` (`BLOCKED` após 3 ciclos — `logs/grep-error.log`)
- [!] **C2.11** `recipes/31-findutils.sh` — `findutils` `4.10.0` (`BLOCKED` após 3 ciclos — `logs/findutils-error.log`)
- [!] **C2.12** `recipes/32-coreutils.sh` — `coreutils` `9.5` (`BLOCKED` após 3 ciclos — `logs/coreutils-error.log`)
- [x] **C2.13** `recipes/33-less.sh` — `less` `668` (`SUCCESS`, 346 KB)
- [x] **C2.14** `recipes/34-file.sh` — `file` `5.46` (`SUCCESS`, 10542 KB)
- [x] **C2.15** `recipes/35-tree.sh` — `tree` `2.3.2` (`SUCCESS`, 88 KB; patch `01-qnx-langinfo.patch`)
- [x] **C2.16** `recipes/36-xxd.sh` — `xxd` `9.2.1393` (`SUCCESS`, 20 KB)

#### Gate Camada 2
- [x] **GATE-C2.1** Todos os 12 pacotes concluídos passaram em `scripts/verify-elf.sh` com `0` erros (`analisados=66 aprovados=66 falhas=0`).
- [x] **GATE-C2.2** Os 5 pacotes que falharam após 3 ciclos estão documentados em `logs/<pacote>-error.log` e marcados como `BLOCKED` no `dist/manifest.json`.
- [x] **GATE-C2.3** Todos os patches criados nesta camada estão salvos em `patches/<pacote>/`.

---

### Camada 3 — Shell, Multiplexador e Produtividade no Teclado Q5

**Pré-requisito:** `GATE-C2` concluído.

- [!] **C3.0** `recipes/40-dash.sh` — `dash` `0.5.12` (`BLOCKED` após 3 ciclos — `logs/dash-error.log`; patch `01-qnx-flushall.patch`)
- [!] **C3.1** `recipes/41-bash.sh` — `bash` `5.2.37` (`BLOCKED` após 3 ciclos — `logs/bash-error.log`)
- [!] **C3.2** `recipes/42-tmux.sh` — `tmux` `3.5a` (`BLOCKED` após 3 ciclos — `logs/tmux-error.log`)
- [!] **C3.3** `recipes/43-nano.sh` — `nano` `8.3` (`BLOCKED` após 3 ciclos — `logs/nano-error.log`; patch `01-qnx-st-mtime.patch`)
- [x] **C3.4** `recipes/44-vim.sh` — `vim` `9.1.1000` (`SUCCESS`, 30936 KB; patch `01-qnx-no-photon.patch`)
- [!] **C3.5** `recipes/45-bc.sh` — `bc` `1.07.1` (`BLOCKED` após 3 ciclos — `logs/bc-error.log`)
- [x] **C3.6** `recipes/46-time.sh` — `time` `1.9` (`SUCCESS`, 69 KB)
- [x] **C3.7** `recipes/47-gettext-base.sh` — `gettext-base` `0.22.5` (`SUCCESS`, 202 KB)

#### Gate Camada 3
- [x] **GATE-C3.1** Todos os binários e bibliotecas gerados passaram em `scripts/verify-elf.sh` com `0` erros (`analisados=71 aprovados=71 falhas=0`).
- [x] **GATE-C3.2** Scripts e shebangs instalados auditados sem caminhos host (`$STAGING` ou `/home/...`).
- [x] **GATE-C3.3** Patches salvos em `patches/<pacote>/` e bloqueios registrados em `logs/<pacote>-error.log` e `dist/manifest.json`.

---

### Camada 4 — Interpretadores e Clientes de Terminal Avançados

**Pré-requisito:** `GATE-C3` concluído.

- [!] **C4.0** `recipes/50-python3.sh` — `python3` `3.12.8` (`BLOCKED` após 3 ciclos — `logs/python3-error.log`; patch `01-qnx-cross-machdep.patch`)
- [x] **C4.1** `recipes/51-bdwgc.sh` — `bdwgc` `8.2.8` (`SUCCESS`, 840 KB)
- [!] **C4.2** `recipes/52-w3m.sh` — `w3m` `0.5.3-git20230121` (`BLOCKED` após 3 ciclos — `logs/w3m-error.log`)
- [x] **C4.3** `recipes/53-mutt.sh` — `mutt` `2.2.13` (`SUCCESS`, 5789 KB)
- [x] **C4.4** `recipes/54-netcat-openbsd.sh` — `netcat-openbsd` `0.7.1` (`SUCCESS`, 60 KB)
- [!] **C4.5** `recipes/55-whois.sh` — `whois` `5.5.23` (`BLOCKED` após 3 ciclos — `logs/whois-error.log`)

#### Gate Camada 4
- [x] **GATE-C4.1** `scripts/verify-elf.sh ${SYSROOT_PREFIX}` retornou `0` erros em todos os binários e bibliotecas dinâmicas (`analisados=77 aprovados=77 falhas=0`).
- [x] **GATE-C4.2** Pacotes bloqueados registrados após 3 tentativas com log em `logs/<pacote>-error.log` e status `BLOCKED` em `dist/manifest.json`.
- [x] **GATE-C4.3** Todos os patches versionados em `patches/`.

---

## Fase 3 — Protocolo Determinístico de Autocorreção (Transversal às Fases 2.0–2.4)

Sempre que `scripts/build-pkg.sh` falhar em qualquer pacote da Fase 2, o agente **DEVE** executar este loop determinístico (máximo `3` ciclos por pacote):

### Loop de Remediação
1. **Inspeção:** Ler as últimas 80 linhas de `logs/<pacote>.log` (e `config.log` se a falha ocorrer no `./configure`).
2. **Classificação e Correção:** Aplicar a ação correspondente da tabela abaixo.
3. **Versionamento:** Se alterou código-fonte, gerar `diff -u` limpo e salvar em `patches/<pacote>/<nn>-<descricao>.patch`. Se alterou flags/cache, atualizar `recipes/<id>-<pacote>.sh`.
4. **Reexecução Limpa:** Rodar novamente `scripts/build-pkg.sh recipes/<id>-<pacote>.sh` a partir de `/tmp/build/<pacote>` limpo.
5. **Isolamento (se Tentativa 3 falhar):**
   - Salvar diagnóstico + últimas 120 linhas do log em `logs/<pacote>-error.log`.
   - Registrar `status: "BLOCKED"` + resumo da causa raiz em `dist/manifest.json`.
   - Marcar `[!]` no item correspondente deste roteiro.
   - Se o pacote for da Camada 0 ou Camada 1 obrigatória, **PARAR** e escalar/resolver antes de prosseguir (pois o Definition of Done exige 100% de sucesso nessas camadas).

### Matriz Determinística de Remediação

| Padrão de Erro Detectado no Log | Ação Corretiva Obrigatória |
| :--- | :--- |
| `undefined reference to 'socket'`, `'connect'`, `'getaddrinfo'`, `'recv'`, `'send'` | Incluir `-lsocket` em `LIBS` ou `LDFLAGS` na receita do pacote. |
| `undefined reference to 'sin'`, `'floor'`, `'pow'`, `'sqrt'`, `'log'` | Incluir `-lm` em `LIBS` ou `LDFLAGS` na receita do pacote. |
| `cannot guess build type` / `Invalid configuration 'arm-blackberry-qnx8eabi'` | Substituir todos os `config.sub` e `config.guess` do tarball pelos arquivos atualizados em `/usr/share/misc/`. |
| `error: sys/sysmacros.h: No such file` ou `epoll.h` ausente | Verificar flags `./configure --disable-epoll` / `--with-select`; se não existir flag, criar patch em `patches/<pacote>/` protegido por `#ifdef __QNXNTO__`. |
| `cannot run test program while cross compiling` | Inspecionar `config.log`, identificar a variável `ac_cv_*` / `gl_cv_*` / `bash_cv_*` / `vim_cv_*` correspondente e pré-defini-la na invocação do `./configure`. |
| `Exec format error` durante `make` | O `Makefile` tentou executar um binário ARM compilado como ferramenta auxiliar no host `x86_64`. Compilar a ferramenta auxiliar com `gcc` do host primeiro e injetá-la via variável (ex.: `HOSTCC=gcc`, `CC_FOR_BUILD=gcc`, `--with-build-python=...`). |
| `fatal error: openssl/ssl.h` ou biblioteca `.so`/`.h` não encontrada | Confirmar que a dependência está em camada anterior do DAG com status `SUCCESS` e que `CFLAGS`, `LDFLAGS`, `PKG_CONFIG_LIBDIR` e `PKG_CONFIG_SYSROOT_DIR` apontam corretamente para `${SYSROOT_PREFIX}` / `${STAGING}`. |

---

## Fase 4 — Empacotamento, Metadados e Entrega (`scripts/package.sh`)

**Pré-requisito:** Camadas 0 a 4 concluídas (Gates `C0` a `C4` encerrados).

### Checklist de Tarefas
- [x] **F4.1** Finalizar `scripts/package.sh` executando sequencialmente:
  1. **Otimização (Strip):** Executar `arm-blackberry-qnx8eabi-strip --strip-unneeded` em todos os executáveis ELF e bibliotecas `.so` dentro de `${SYSROOT_PREFIX}`, preservando intactos scripts shell, Python, Perl, arquivos de texto e certificados.
  2. **Revalidação Pós-Strip:** Rodar `scripts/verify-elf.sh ${SYSROOT_PREFIX}` após o strip para garantir que nenhum ELF foi corrompido.
  3. **Geração de `${SYSROOT_PREFIX}/env.sh`** com exatamente o seguinte contrato:
     ```sh
     export PREFIX="/accounts/1000/shared/misc/berrycore"
     export PATH="$PREFIX/bin:$PREFIX/sbin:$PATH"
     export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
     export TERMINFO="$PREFIX/share/terminfo"
     export SSL_CERT_FILE="$PREFIX/etc/ssl/certs/ca-certificates.crt"
     export CURL_CA_BUNDLE="$PREFIX/etc/ssl/certs/ca-certificates.crt"
     export MANPATH="$PREFIX/share/man:$MANPATH"
     ```
  4. **Empacotamento Modular:** Gerar `dist/packages/<pacote>-<versao>-bb10-armv7le.zip` para cada pacote com status `SUCCESS`, mantendo caminhos relativos à raiz `$PREFIX` (ex.: `bin/...`, `lib/...`, `share/...`, `etc/...`).
  5. **Empacotamento Consolidado:** Gerar `dist/berrycore-debian-suite-armv7le.zip` contendo integralmente o conteúdo de `${SYSROOT_PREFIX}` (caminhos relativos a `$PREFIX`).
  6. **Checksums:** Gerar `dist/SHA256SUMS` cobrindo `berrycore-debian-suite-armv7le.zip` e todos os arquivos em `packages/*.zip`.
  7. **Manifesto JSON:** Gerar/atualizar `dist/manifest.json` com o esquema:
     ```json
     {
       "target": "arm-blackberry-qnx8eabi",
       "prefix": "/accounts/1000/shared/misc/berrycore",
       "generated_at": "ISO-8601",
       "summary": { "total": 0, "success": 0, "blocked": 0 },
       "packages": [
         {
           "id": "00",
           "name": "zlib",
           "version": "1.3.1",
           "layer": 0,
           "status": "SUCCESS",
           "size_kb": 123,
           "binaries": [],
           "libraries": [],
           "needed": [],
           "patches": [],
           "error_summary": null
         }
       ]
     }
     ```
- [x] **F4.2** Executar `scripts/package.sh` dentro do contêiner Docker (`77` ELFs stripped e revalidados com `0` falhas; `33` zips modulares + bundle consolidado gerados).
- [x] **F4.3** Gerar `BUILD_REPORT.md` na raiz do repositório contendo:
  - Resumo executivo e taxa de sucesso (global e por camada).
  - Tabela completa de pacotes compilados (nome, versão, camada, status, tamanho em KB).
  - Inventário de patches criados em `patches/` com justificativa técnica QNX.
  - Lista de pacotes `BLOCKED` (se houver) com resumo da causa raiz e ponteiro para `logs/<pacote>-error.log`.
  - **Guia de Instalação no BlackBerry Q5 (Term49):** comandos exatos para extrair `berrycore-debian-suite-armv7le.zip` em `/accounts/1000/shared/misc/berrycore`, carregar `source /accounts/1000/shared/misc/berrycore/env.sh` e executar testes de sanidade (`curl --version`, `openssl version`, `ssh -V`).

### Gate 4 — Critério de Aceitação (Bloqueante)
- [x] **GATE-4.1** `dist/berrycore-debian-suite-armv7le.zip` existe e `unzip -t dist/berrycore-debian-suite-armv7le.zip` retornou `0`.
- [x] **GATE-4.2** `(cd dist && sha256sum -c SHA256SUMS)` retornou `0` para 100% dos 34 arquivos listados.
- [x] **GATE-4.3** `jq empty dist/manifest.json` validou JSON bem-formado e consistente com todos os 46 pacotes do DAG.
- [x] **GATE-4.4** `BUILD_REPORT.md` gerado, completo e sem placeholders pendentes.

---

## Fase 5 — Auditoria Final (Definition of Done)

**Pré-requisito:** `GATE-4` aprovado.

Executar esta verificação final antes de encerrar a execução autônoma:

- [x] **DOD.1** Imagem Docker constrói do zero sem intervenção manual (`docker build` = código `0`).
- [x] **DOD.2** `scripts/run-all.sh` concluiu todas as camadas do DAG e registrou cada resultado em `dist/manifest.json` (`33` `SUCCESS`, `13` `BLOCKED` em camadas não-críticas).
- [x] **DOD.3** 100% dos pacotes obrigatórios da Camada 0 (9/9) e Camada 1 (6/6) (`zlib`, `ncurses`, `readline`, `libevent`, `pcre2`, `libffi`, `expat`, `sqlite3`, `ca-certificates`, `openssl`, `nghttp2`, `curl`, `wget`, `openssh-client`, `rsync`) possuem status `SUCCESS`.
- [x] **DOD.4** `scripts/verify-elf.sh` reportou **0 erros** em todos os artefatos incluídos no `dist/berrycore-debian-suite-armv7le.zip` (`analisados=77 aprovados=77 falhas=0`).
- [x] **DOD.5** Auditoria de *host leakage* (`grep -rnE '/workspace/staging|/home/|/usr/lib' ${SYSROOT_PREFIX}/env.sh ${SYSROOT_PREFIX}/lib/pkgconfig 2>/dev/null`) retornou vazio.
- [x] **DOD.6** Todos os patches aplicados estão versionados em `patches/` (nenhuma alteração manual perdida em `/tmp`).
- [x] **DOD.7** `dist/berrycore-debian-suite-armv7le.zip`, `dist/SHA256SUMS`, `dist/manifest.json` e `BUILD_REPORT.md` estão presentes e íntegros.
- [x] **DOD.8** Todos os checkboxes deste roteiro estão atualizados com o estado final (`[x]` ou `[!]`) e o Painel de Rastreamento (Seção 0.5) está preenchido.
