# Relatório Final de Build — Debian-to-BerryCore (BlackBerry Q5 / QNX Neutrino)

- **Gerado em:** `2026-11-23T20:55:35Z`
- **Alvo (Target Triple):** `arm-blackberry-qnx8eabi` (`armv7le`, softfp)
- **Prefixo no Dispositivo (`PREFIX`):** `/accounts/1000/shared/misc/berrycore`
- **Bundle Consolidado:** `dist/berrycore-debian-suite-armv7le.zip`
- **Taxa de Sucesso:** **33/46 (71.7%)** | Bloqueados: **13**

## Pacotes Compilados e Status por Camada

| ID | Camada | Pacote | Versão | Status | Tamanho (KB) | Binários |
| :--- | :---: | :--- | :--- | :---: | ---: | :--- |
| `00` | 0 | `zlib` | `1.4` | **SUCCESS** | 256 | — |
| `01` | 0 | `ncurses` | `6.5` | **SUCCESS** | 4629 | `clear`, `infocmp`, `tabs`, `tic`, `toe`, `tput` (+1) |
| `02` | 0 | `readline` | `8.2.13` | **SUCCESS** | 1253 | — |
| `03` | 0 | `libevent` | `2.1.13-stable` | **SUCCESS** | 1527 | — |
| `04` | 0 | `pcre2` | `10.49` | **SUCCESS** | 3851 | `pcre2grep`, `pcre2test` |
| `05` | 0 | `libffi` | `3.8.1` | **SUCCESS** | 63 | — |
| `06` | 0 | `expat` | `2.10.0` | **SUCCESS** | 502 | `xmlwf` |
| `07` | 0 | `sqlite3` | `3.47.2` | **SUCCESS** | 3559 | `sqlite3` |
| `08` | 0 | `ca-certificates` | `2025-10` | **SUCCESS** | 196 | — |
| `10` | 1 | `openssl` | `3.5.9` | **SUCCESS** | 11832 | `openssl` |
| `11` | 1 | `nghttp2` | `1.71.0` | **SUCCESS** | 705 | — |
| `12` | 1 | `curl` | `8.23.0` | **SUCCESS** | 3768 | `curl` |
| `13` | 1 | `wget` | `1.25.0` | **SUCCESS** | 695 | `wget` |
| `14` | 1 | `openssh-client` | `10.6p2` | **SUCCESS** | 1548 | `scp`, `sftp`, `ssh`, `ssh-agent`, `ssh-keygen` |
| `15` | 1 | `rsync` | `3.5.2` | **SUCCESS** | 699 | `rsync` |
| `20` | 2 | `bzip2` | `1.0.8` | **SUCCESS** | 178 | `bzip2`, `bzip2recover` |
| `21` | 2 | `xz-utils` | `5.8.4` | **SUCCESS** | 753 | `lzmadec`, `lzmainfo`, `xz`, `xzdec` |
| `22` | 2 | `gzip` | `1.13` | **SUCCESS** | 191 | `gzip` |
| `23` | 2 | `tar` | `1.35` | **BLOCKED** | 0 | — |
| `24` | 2 | `zip` | `3.0` | **SUCCESS** | 323 | `zip`, `zipcloak`, `zipnote`, `zipsplit` |
| `25` | 2 | `unzip` | `6.0` | **SUCCESS** | 185 | `funzip`, `unzip`, `unzipsfx` |
| `26` | 2 | `diffutils` | `3.10` | **BLOCKED** | 0 | — |
| `27` | 2 | `patch` | `2.7.6` | **SUCCESS** | 173 | `patch` |
| `28` | 2 | `sed` | `4.9` | **SUCCESS** | 321 | `sed` |
| `29` | 2 | `mawk` | `1.3.4-20250131` | **SUCCESS** | 206 | `mawk` |
| `30` | 2 | `grep` | `3.11` | **BLOCKED** | 0 | — |
| `31` | 2 | `findutils` | `4.10.0` | **BLOCKED** | 0 | — |
| `32` | 2 | `coreutils` | `9.5` | **BLOCKED** | 0 | — |
| `33` | 2 | `less` | `668` | **SUCCESS** | 284 | `less`, `lessecho`, `lesskey` |
| `34` | 2 | `file` | `5.46` | **SUCCESS** | 10510 | `file` |
| `35` | 2 | `tree` | `2.3.2` | **SUCCESS** | 73 | `tree` |
| `36` | 2 | `xxd` | `9.2.1393` | **SUCCESS** | 15 | `xxd` |
| `40` | 3 | `dash` | `0.5.12` | **BLOCKED** | 0 | — |
| `41` | 3 | `bash` | `5.2.37` | **BLOCKED** | 0 | — |
| `42` | 3 | `tmux` | `3.5a` | **BLOCKED** | 0 | — |
| `43` | 3 | `nano` | `8.3` | **BLOCKED** | 0 | — |
| `44` | 3 | `vim` | `9.1.1000` | **SUCCESS** | 30468 | `vim`, `xxd` |
| `45` | 3 | `bc` | `1.07.1` | **BLOCKED** | 0 | — |
| `46` | 3 | `time` | `1.9` | **SUCCESS** | 61 | `time` |
| `47` | 3 | `gettext-base` | `0.22.5` | **SUCCESS** | 174 | `envsubst`, `gettext`, `ngettext` |
| `50` | 4 | `python3` | `3.12.8` | **BLOCKED** | 0 | — |
| `51` | 4 | `bdwgc` | `8.2.8` | **SUCCESS** | 792 | — |
| `52` | 4 | `w3m` | `0.5.3-git20230121` | **BLOCKED** | 0 | — |
| `53` | 4 | `mutt` | `2.2.13` | **SUCCESS** | 5649 | `mutt`, `mutt_pgpring`, `pgpewrap` |
| `54` | 4 | `netcat-openbsd` | `0.7.1` | **SUCCESS** | 49 | `netcat` |
| `55` | 4 | `whois` | `5.5.23` | **BLOCKED** | 0 | — |

## Patches QNX Versionados (`patches/`)

- `patches/dash/01-qnx-flushall.patch`
- `patches/libevent/01-qnx-sa-restart.patch`
- `patches/libevent/02-qnx-syslog.patch`
- `patches/nano/01-qnx-st-mtime.patch`
- `patches/ncurses/01-qnx8eabi-shlib.patch`
- `patches/ncurses/02-qnx-wcwidth.patch`
- `patches/openssh-client/01-qnx-syslog.patch`
- `patches/openssl/01-qnx-no-syslog.patch`
- `patches/python3/01-qnx-cross-machdep.patch`
- `patches/readline/01-qnx-sigset.patch`
- `patches/rsync/01-qnx-syslog.patch`
- `patches/rsync/02-qnx-at-removedir.patch`
- `patches/sed/01-qnx-pselect-time.patch`
- `patches/tar/01-qnx-makedev.patch`
- `patches/tree/01-qnx-langinfo.patch`
- `patches/vim/01-qnx-no-photon.patch`
- `patches/wget/01-qnx-pselect-time.patch`

## Pacotes Bloqueados (`BLOCKED`)

- **`tar` (1.35)** — Falha no build/validação; consultar logs/tar-error.log (`logs/tar-error.log`)
- **`diffutils` (3.10)** — Falha no build/validação; consultar logs/diffutils-error.log (`logs/diffutils-error.log`)
- **`grep` (3.11)** — Falha no build/validação; consultar logs/grep-error.log (`logs/grep-error.log`)
- **`findutils` (4.10.0)** — Falha no build/validação; consultar logs/findutils-error.log (`logs/findutils-error.log`)
- **`coreutils` (9.5)** — Falha no build/validação; consultar logs/coreutils-error.log (`logs/coreutils-error.log`)
- **`dash` (0.5.12)** — Falha no build/validação; consultar logs/dash-error.log (`logs/dash-error.log`)
- **`bash` (5.2.37)** — Falha no build/validação; consultar logs/bash-error.log (`logs/bash-error.log`)
- **`tmux` (3.5a)** — Falha no build/validação; consultar logs/tmux-error.log (`logs/tmux-error.log`)
- **`nano` (8.3)** — Falha no build/validação; consultar logs/nano-error.log (`logs/nano-error.log`)
- **`bc` (1.07.1)** — Falha no build/validação; consultar logs/bc-error.log (`logs/bc-error.log`)
- **`python3` (3.12.8)** — Falha no build/validação; consultar logs/python3-error.log (`logs/python3-error.log`)
- **`w3m` (0.5.3-git20230121)** — Falha no build/validação; consultar logs/w3m-error.log (`logs/w3m-error.log`)
- **`whois` (5.5.23)** — Falha no build/validação; consultar logs/whois-error.log (`logs/whois-error.log`)

## Instruções de Instalação no BlackBerry Q5 (Term49)

1. Copie `dist/berrycore-debian-suite-armv7le.zip` e `dist/SHA256SUMS` para o dispositivo (ex.: `/accounts/1000/shared/downloads/`).
2. No **Term49**, crie o diretório alvo e extraia o bundle mantendo a hierarquia relativa a `$PREFIX`:

```sh
mkdir -p /accounts/1000/shared/misc/berrycore
unzip -o /accounts/1000/shared/downloads/berrycore-debian-suite-armv7le.zip -d /accounts/1000/shared/misc/berrycore
source /accounts/1000/shared/misc/berrycore/env.sh
```

3. Para ativar automaticamente em toda sessão do Term49, adicione ao seu perfil (`~/.profile`):

```sh
echo "source /accounts/1000/shared/misc/berrycore/env.sh" >> ~/.profile
```

4. Validação rápida no dispositivo:

```sh
openssl version
curl --version
ssh -V
```
