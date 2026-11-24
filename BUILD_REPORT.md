# Relatório Final de Build — Debian-to-BerryCore (BlackBerry Q5 / QNX Neutrino)

- **Gerado em:** `2026-11-24T19:49:03Z`
- **Alvo (Target Triple):** `arm-blackberry-qnx8eabi` (`armv7le`, softfp)
- **Prefixo no Dispositivo (`PREFIX`):** `/accounts/1000/shared/misc/berrycore`
- **Bundle Consolidado:** `dist/berrycore-debian-suite-armv7le.zip`
- **Taxa de Sucesso:** **51/51 (100.0%)** | Bloqueados: **0**

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
| `23` | 2 | `tar` | `1.35` | **SUCCESS** | 1040 | `tar` |
| `24` | 2 | `zip` | `3.0` | **SUCCESS** | 323 | `zip`, `zipcloak`, `zipnote`, `zipsplit` |
| `25` | 2 | `unzip` | `6.0` | **SUCCESS** | 185 | `funzip`, `unzip`, `unzipsfx` |
| `26` | 2 | `diffutils` | `3.10` | **SUCCESS** | 452 | `cmp`, `diff`, `diff3`, `sdiff` |
| `27` | 2 | `patch` | `2.7.6` | **SUCCESS** | 173 | `patch` |
| `28` | 2 | `sed` | `4.9` | **SUCCESS** | 321 | `sed` |
| `29` | 2 | `mawk` | `1.3.4-20250131` | **SUCCESS** | 206 | `mawk` |
| `30` | 2 | `grep` | `3.11` | **SUCCESS** | 317 | `grep` |
| `31` | 2 | `findutils` | `4.10.0` | **SUCCESS** | 934 | `find`, `locate`, `xargs`, `frcode` |
| `32` | 2 | `coreutils` | `9.5` | **SUCCESS** | 7444 | `[`, `b2sum`, `base32`, `base64`, `basename`, `basenc` (+89) |
| `33` | 2 | `less` | `668` | **SUCCESS** | 284 | `less`, `lessecho`, `lesskey` |
| `34` | 2 | `file` | `5.46` | **SUCCESS** | 10510 | `file` |
| `35` | 2 | `tree` | `2.3.2` | **SUCCESS** | 73 | `tree` |
| `36` | 2 | `xxd` | `9.2.1393` | **SUCCESS** | 15 | `xxd` |
| `40` | 3 | `dash` | `0.5.12` | **SUCCESS** | 136 | `dash` |
| `41` | 3 | `bash` | `5.2.37` | **SUCCESS** | 3513 | `bash` |
| `42` | 3 | `tmux` | `3.5a` | **SUCCESS** | 797 | `tmux` |
| `43` | 3 | `nano` | `8.3` | **SUCCESS** | 589 | `nano` |
| `44` | 3 | `vim` | `9.1.1000` | **SUCCESS** | 30468 | `vim`, `xxd` |
| `45` | 3 | `bc` | `1.07.1` | **SUCCESS** | 329 | `bc`, `dc` |
| `46` | 3 | `time` | `1.9` | **SUCCESS** | 61 | `time` |
| `47` | 3 | `gettext-base` | `0.22.5` | **SUCCESS** | 174 | `envsubst`, `gettext`, `ngettext` |
| `50` | 4 | `python3` | `3.12.8` | **SUCCESS** | 140112 | `python3.12` |
| `51` | 4 | `bdwgc` | `8.2.8` | **SUCCESS** | 796 | — |
| `52` | 4 | `w3m` | `0.5.3-git20230121` | **SUCCESS** | 719 | `w3m`, `w3mbookmark`, `w3mhelperpanel`, `inflate` |
| `53` | 4 | `mutt` | `2.2.13` | **SUCCESS** | 5649 | `mutt`, `mutt_pgpring`, `pgpewrap` |
| `54` | 4 | `netcat-openbsd` | `0.7.1` | **SUCCESS** | 49 | `netcat` |
| `55` | 4 | `whois` | `5.5.23` | **SUCCESS** | 81 | `whois` |
| `60` | 5 | `jq` | `1.8.2` | **SUCCESS** | 2033 | `jq` |
| `61` | 5 | `fzy` | `1.1` | **SUCCESS** | 26 | `fzy` |
| `62` | 5 | `ncdu` | `1.21` | **SUCCESS** | 75 | `ncdu` |
| `64` | 5 | `git` | `2.47.1` | **SUCCESS** | 17726 | `git`, `git-shell`, `scalar`, `git`, `git-daemon`, `git-http-backend` (+6) |
| `65` | 5 | `q5-ux` | `1.0.0` | **SUCCESS** | 13 | — |

## Patches QNX Versionados (`patches/`)

- `patches/bdwgc/01-qnx-arm32-stackbottom.patch`
- `patches/coreutils/01-qnx-mountlist.patch`
- `patches/coreutils/02-qnx-pselect-time.patch`
- `patches/coreutils/03-qnx-boot-time-aux.patch`
- `patches/coreutils/04-qnx-mknod-makedev.patch`
- `patches/dash/01-qnx-flushall.patch`
- `patches/dash/02-qnx-stpncpy.patch`
- `patches/diffutils/01-qnx-sigsegv-time.patch`
- `patches/diffutils/02-qnx-pselect-time.patch`
- `patches/findutils/01-qnx-mountlist.patch`
- `patches/findutils/02-qnx-fdleak-time.patch`
- `patches/findutils/03-qnx-pselect-time.patch`
- `patches/findutils/04-qnx-stpcpy-chk.patch`
- `patches/fzy/01-qnx-tty-time.patch`
- `patches/git/01-qnx-syslog.patch`
- `patches/git/02-qnx-test-delay.patch`
- `patches/grep/01-qnx-sigsegv-time.patch`
- `patches/grep/02-qnx-pselect-time.patch`
- `patches/jq/01-qnx-xopen-source.patch`
- `patches/libevent/01-qnx-sa-restart.patch`
- `patches/libevent/02-qnx-syslog.patch`
- `patches/nano/01-qnx-st-mtime.patch`
- `patches/ncurses/01-qnx8eabi-shlib.patch`
- `patches/ncurses/02-qnx-wcwidth.patch`
- `patches/openssh-client/01-qnx-syslog.patch`
- `patches/openssl/01-qnx-no-syslog.patch`
- `patches/python3/01-qnx-cross-machdep.patch`
- `patches/python3/02-qnx-posixmodule.patch`
- `patches/readline/01-qnx-sigset.patch`
- `patches/rsync/01-qnx-syslog.patch`
- `patches/rsync/02-qnx-at-removedir.patch`
- `patches/sed/01-qnx-pselect-time.patch`
- `patches/tar/01-qnx-makedev.patch`
- `patches/tar/02-qnx-stpcpy-chk.patch`
- `patches/tmux/01-qnx-langinfo.patch`
- `patches/tmux/02-qnx-iov-max.patch`
- `patches/tree/01-qnx-langinfo.patch`
- `patches/vim/01-qnx-no-photon.patch`
- `patches/wget/01-qnx-pselect-time.patch`
- `patches/whois/01-qnx-no-xopen-conflict.patch`

## Pacotes Bloqueados (`BLOCKED`)

- Nenhum pacote bloqueado.

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
