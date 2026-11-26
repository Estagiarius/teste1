# recipes/66-q5-sheet.sh — Camada 5: Planilha de cálculo CLI/TUI nativa em C11 + ncursesw (sem Python)
PKG_ID="66"
PKG_NAME="q5-sheet"
PKG_VER="1.0.0"
PKG_LAYER="5"
PKG_CRITICAL="0"
PKG_DEPS="ncurses"
PKG_URL=""
PKG_SHA256=""

build() {
    mkdir -p "${BUILD_ROOT}"
    # shellcheck disable=SC2086
    "${CC}" -std=c11 -Wall -Wextra ${CFLAGS} \
        -I"${SYSROOT_PREFIX}/include/ncursesw" \
        -o "${BUILD_ROOT}/q5-sheet" \
        "${WORKSPACE_ROOT}/src/q5-sheet/q5-sheet.c" \
        ${LDFLAGS} -lncursesw -lm -lsocket
}

install_staging() {
    install -d "${SYSROOT_PREFIX}/bin" "${SYSROOT_PREFIX}/share/q5-sheet"
    install -m 755 "${BUILD_ROOT}/q5-sheet" "${SYSROOT_PREFIX}/bin/q5-sheet"

    cat > "${SYSROOT_PREFIX}/share/q5-sheet/exemplo.csv" <<'EOF'
Item,Qtd,Unitario,Subtotal
Aluguel,1,1200,=(B2*C2)
Mercado,4,185.50,=B3*C3
Energia,1,142.30,=B4*C4
Internet,1,99.90,=B5*C5
Transporte,20,5.50,=B6*C6
Total,=SUM(B2:B6),=AVG(C2:C6),=SUM(D2:D6)
Minimo,,,=MIN(D2:D6)
Maximo,,,=MAX(D2:D6)
Itens,,,=COUNT(D2:D6)
EOF
    chmod 644 "${SYSROOT_PREFIX}/share/q5-sheet/exemplo.csv"
}
