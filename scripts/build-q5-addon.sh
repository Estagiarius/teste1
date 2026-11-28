#!/usr/bin/env bash
# scripts/build-q5-addon.sh — Gera pacote enxuto e seguro (zero conflito) para instalar
# por cima do BerryCore oficial (sw7ft/BerryCore v0.90.x) no BlackBerry Q5.
#
# Uso (dentro do container Docker bb10-berrycore-builder:latest):
#   /workspace/scripts/build-q5-addon.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/env-cross.sh"

ADDON_STAGE="/tmp/q5-addon-stage"
OUT_ZIP="${WORKSPACE_ROOT}/dist/q5-berrycore-addon.zip"

rm -rf "${ADDON_STAGE}"
mkdir -p "${ADDON_STAGE}/bin" \
         "${ADDON_STAGE}/lib" \
         "${ADDON_STAGE}/etc/skel" \
         "${ADDON_STAGE}/share/q5-sheet" \
         "${ADDON_STAGE}/share/q5-addon"

echo "=== [1/4] Compilando q5-sheet portatil (libncursesw estatico — zero deps extras) ==="
# shellcheck disable=SC2086
"${CC}" -std=c11 -Wall -Wextra ${CFLAGS} \
    -I"${SYSROOT_PREFIX}/include/ncursesw" \
    -o "${ADDON_STAGE}/bin/q5-sheet" \
    "${WORKSPACE_ROOT}/src/q5-sheet/q5-sheet.c" \
    "${SYSROOT_PREFIX}/lib/libncursesw.a" \
    -lm -lsocket
"${STRIP}" "${ADDON_STAGE}/bin/q5-sheet"

echo "=== [2/4] Copiando binarios e libs exclusivas do Q5 (sem tocar no core do BerryCore) ==="
for b in fzy ncdu jq tree; do
    if [[ -f "${SYSROOT_PREFIX}/bin/${b}" ]]; then
        cp -a "${SYSROOT_PREFIX}/bin/${b}" "${ADDON_STAGE}/bin/${b}"
    fi
done

# Libs necessarias apenas se ausentes no BerryCore oficial (nunca sobrescrevem existentes)
cp -a "${SYSROOT_PREFIX}/lib/libncursesw.so.6.5" "${ADDON_STAGE}/lib/"
ln -sf libncursesw.so.6.5 "${ADDON_STAGE}/lib/libncursesw.so.6"
cp -a "${SYSROOT_PREFIX}/lib/libjq.so.1" "${ADDON_STAGE}/lib/"
cp -a "${SYSROOT_PREFIX}/lib/libonig.so.10" "${ADDON_STAGE}/lib/"

# Exemplo da planilha + manual do iniciante
cp -a "${SYSROOT_PREFIX}/share/q5-sheet/exemplo.csv" "${ADDON_STAGE}/share/q5-sheet/"
if [[ -f "${WORKSPACE_ROOT}/MANUAL_INICIANTE_BERRYCORE.md" ]]; then
    cp -a "${WORKSPACE_ROOT}/MANUAL_INICIANTE_BERRYCORE.md" "${ADDON_STAGE}/share/q5-addon/"
fi

# Scripts q5-ux com shebangs portaveis (/usr/bin/env) e sem colidir com 'ai' do bcllm
for s in q5-files bc-menu note; do
    sed -e '1s|^#!/accounts/1000/shared/misc/berrycore/bin/bash$|#!/usr/bin/env bash|' \
        -e '1s|^#!/accounts/1000/shared/misc/berrycore/bin/python3$|#!/usr/bin/env python3|' \
        "${SYSROOT_PREFIX}/bin/${s}" > "${ADDON_STAGE}/bin/${s}"
    chmod 755 "${ADDON_STAGE}/bin/${s}"
done

# Instala nosso cliente 'ai' como 'q5-ai' para nao sobrescrever o 'ai' (bcllm) do BerryCore oficial
sed -e '1s|^#!/accounts/1000/shared/misc/berrycore/bin/bash$|#!/usr/bin/env bash|' \
    "${SYSROOT_PREFIX}/bin/ai" > "${ADDON_STAGE}/bin/q5-ai"
chmod 755 "${ADDON_STAGE}/bin/q5-ai"

# Dotfiles Q5 (55 colunas) em etc/skel/
for d in .inputrc .tmux.conf .vimrc .nanorc; do
    cp -a "${SYSROOT_PREFIX}/etc/skel/${d}" "${ADDON_STAGE}/etc/skel/${d}"
done

# Cria .bashrc.q5 (aditivo: preserva o .profile e env.sh do BerryCore oficial)
cat > "${ADDON_STAGE}/etc/skel/.bashrc.q5" <<'EOF'
# BerryCore Q5 Pocket Laptop Addon (otimizado para tela 720x720 / ~55 colunas)
export BC="${NATIVE_TOOLS:-/accounts/1000/shared/misc/berrycore}"
export SD="/accounts/1000/removable/sdcard"
export DL="/accounts/1000/shared/downloads"
export DOCS="/accounts/1000/shared/documents"
export NOTES_DIR="${NOTES_DIR:-$DOCS/notes}"
export EDITOR="${EDITOR:-vim}"
export PAGER="less -R"

# Aliases ergonomicos para teclado fisico do Q5
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lh'
alias la='ls -lAh'
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias v='vim'
alias n='nano'
alias f='q5-files'
alias m='bc-menu'
alias sheet='q5-sheet'
alias sd="cd $SD"
alias clima='curl -s "https://wttr.in/?0&T&lang=pt"'

# Atalhos fuzzy com fzy
fh() {
    local cmd
    cmd="$(history | awk '{$1=""; sub(/^ /, ""); print}' | awk '!seen[$0]++' | fzy -l 12)" || return
    [ -n "$cmd" ] && eval "$cmd"
}
ff() {
    local file
    file="$(find . -maxdepth 4 -type f 2>/dev/null | sed 's|^\./||' | fzy -l 12)" || return
    [ -n "$file" ] && "${EDITOR:-vim}" "$file"
}
fcd() {
    local dir
    dir="$(find . -maxdepth 4 -type d 2>/dev/null | sed 's|^\./||' | fzy -l 12)" || return
    [ -n "$dir" ] && cd "$dir"
}

# Sessao tmux pre-montada
work() {
    if tmux has-session -t q5 2>/dev/null; then
        tmux attach -t q5
    else
        tmux new-session -d -s q5 -n sh
        tmux new-window -t q5:2 -n files 'q5-files || bash'
        tmux new-window -t q5:3 -n notes 'note || bash'
        tmux select-window -t q5:1
        tmux attach -t q5
    fi
}
EOF

# q5-setup seguro para conviver com BerryCore v0.90.x oficial
cat > "${ADDON_STAGE}/bin/q5-setup" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BC="${NATIVE_TOOLS:-/accounts/1000/shared/misc/berrycore}"
SKEL="$BC/etc/skel"
TS="$(date +%Y%m%d-%H%M%S)"

echo "== Instalando dotfiles Q5 (55 colunas) em $HOME =="
for f in .inputrc .tmux.conf .vimrc .nanorc .bashrc.q5; do
    if [ -e "$HOME/$f" ]; then
        cp -a "$HOME/$f" "$HOME/${f}.bak.${TS}"
        echo "  backup: $HOME/${f}.bak.${TS}"
    fi
    cp -f "$SKEL/$f" "$HOME/$f"
    echo "  instalado: $HOME/$f"
done

if [ ! -f "$HOME/.bashrc" ] || ! grep -q ".bashrc.q5" "$HOME/.bashrc" 2>/dev/null; then
    printf '\n# BerryCore Q5 Addon\n[ -f "$HOME/.bashrc.q5" ] && source "$HOME/.bashrc.q5"\n' >> "$HOME/.bashrc"
    echo "  atualizado: $HOME/.bashrc (preservando configuracoes anteriores)"
fi

mkdir -p "/accounts/1000/shared/documents/notes"
echo ""
echo "Pronto! Rode 'source ~/.bashrc' e teste:"
echo "  q5-sheet $BC/share/q5-sheet/exemplo.csv"
echo "  bc-menu  (ou atalho: m)"
EOF
chmod 755 "${ADDON_STAGE}/bin/q5-setup"

# Instalador seguro POSIX sh que NAO sobrescreve env.sh, qpkg ou libs ja existentes
cat > "${ADDON_STAGE}/install-q5-addon.sh" <<'EOF'
#!/bin/sh
# Instalador seguro do Q5 Addon Pack sobre o BerryCore oficial (v0.90.x)
set -e

BC="${NATIVE_TOOLS:-/accounts/1000/shared/misc/berrycore}"
SRC_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

echo "=== Instalando Q5 Addon Pack em $BC ==="
mkdir -p "$BC/bin" "$BC/lib" "$BC/etc/skel" "$BC/share/q5-sheet" "$BC/share/q5-addon"

# 1. Binarios exclusivos Q5 (nao sobrescreve env.sh, qpkg, vim, git, curl, openssl, python)
for b in q5-sheet fzy ncdu jq tree q5-setup bc-menu q5-files note q5-ai; do
    if [ -f "$SRC_DIR/bin/$b" ]; then
        cp -f "$SRC_DIR/bin/$b" "$BC/bin/$b"
        chmod 755 "$BC/bin/$b"
        echo "  [+] bin/$b"
    fi
done

# 2. Bibliotecas compartilhadas: instala APENAS se ainda nao existirem no BerryCore oficial
if [ ! -e "$BC/lib/libncursesw.so.6" ]; then
    cp -f "$SRC_DIR/lib/libncursesw.so.6.5" "$BC/lib/libncursesw.so.6.5"
    ln -sf libncursesw.so.6.5 "$BC/lib/libncursesw.so.6"
    echo "  [+] lib/libncursesw.so.6 (adicionada)"
else
    echo "  [=] lib/libncursesw.so.6 ja existe no BerryCore (preservada)"
fi

for lib in libjq.so.1 libonig.so.10; do
    if [ ! -e "$BC/lib/$lib" ]; then
        cp -f "$SRC_DIR/lib/$lib" "$BC/lib/$lib"
        echo "  [+] lib/$lib"
    else
        echo "  [=] lib/$lib ja existe (preservada)"
    fi
done

# 3. Dotfiles e arquivos de exemplo/manual
cp -f "$SRC_DIR/etc/skel/"* "$BC/etc/skel/" 2>/dev/null || true
cp -f "$SRC_DIR/etc/skel/".* "$BC/etc/skel/" 2>/dev/null || true
cp -f "$SRC_DIR/share/q5-sheet/exemplo.csv" "$BC/share/q5-sheet/"
if [ -f "$SRC_DIR/share/q5-addon/MANUAL_INICIANTE_BERRYCORE.md" ]; then
    cp -f "$SRC_DIR/share/q5-addon/MANUAL_INICIANTE_BERRYCORE.md" "$BC/share/q5-addon/"
fi

echo ""
echo "=== Instalacao concluida sem conflitos! ==="
echo "Proximos passos:"
echo "  1. q5-setup        (instala atalhos Q5 preservando seu BerryCore)"
echo "  2. q5-sheet $BC/share/q5-sheet/exemplo.csv"
EOF
chmod 755 "${ADDON_STAGE}/install-q5-addon.sh"

echo "=== [3/4] Validando todos os ELFs do addon com verify-elf.sh ==="
"${SCRIPT_DIR}/verify-elf.sh" "${ADDON_STAGE}"

echo "=== [4/4] Gerando ${OUT_ZIP} ==="
rm -f "${OUT_ZIP}"
(
    cd "${ADDON_STAGE}"
    zip -q -9 -r -y "${OUT_ZIP}" .
)

echo "=== Inspecao final do q5-sheet portatil e do ZIP ==="
arm-blackberry-qnx8eabi-readelf -d "${ADDON_STAGE}/bin/q5-sheet" | grep -E "NEEDED|RPATH|RUNPATH" || true
unzip -l "${OUT_ZIP}"
ls -lh "${OUT_ZIP}"
