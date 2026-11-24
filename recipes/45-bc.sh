# recipes/45-bc.sh — Camada 3: GNU bc (com compilação do gerador fbc no host)
PKG_ID="45"
PKG_NAME="bc"
PKG_VER="1.07.1"
PKG_LAYER="3"
PKG_CRITICAL="0"
PKG_DEPS="ncurses readline"
PKG_URL="https://ftp.gnu.org/gnu/bc/bc-1.07.1.tar.gz"
PKG_SHA256="SKIP"

build() {
    # 1. Compila fbc nativo no host para gerar libmath.h sem Exec format error
    local host_build="${BUILD_DIR}/host-bc"
    rm -rf "${host_build}"
    cp -a "${SRC_DIR}" "${host_build}"
    (
        cd "${host_build}"
        env -u CFLAGS -u CXXFLAGS -u CPPFLAGS -u LDFLAGS -u LIBS \
            -u CPP -u AR -u AS -u LD -u RANLIB -u STRIP -u NM \
            -u PKG_CONFIG_LIBDIR -u PKG_CONFIG_SYSROOT_DIR \
            CC="${HOSTCC}" \
            ./configure --without-readline --without-libedit
        cat > bc/fix-libmath_h <<'PYSH'
#!/usr/bin/env python3
with open("libmath.h", "r", encoding="utf-8") as fh:
    lines = [l.rstrip("\r\n") for l in fh]
if lines:
    lines = lines[:-1]
out = [f'"{l}",' for l in lines]
if out:
    out[0] = "{" + out[0]
    out[-1] = out[-1][:-1] + ",0}"
with open("libmath.h", "w", encoding="utf-8") as fh:
    fh.write("\n".join(out) + "\n")
PYSH
        chmod +x bc/fix-libmath_h
        make -j"${JOBS}" -C lib
        make -C bc libmath.h
    )

    # 2. Preserva libmath.h gerado pelo fbc do host e substitui a regra de geração no Makefile.in
    cp -f "${host_build}/bc/libmath.h" "${SRC_DIR}/bc/libmath.h.prebuilt"
    cp -f "${host_build}/bc/libmath.h" "${SRC_DIR}/bc/libmath.h"
    python3 - "${SRC_DIR}/bc/Makefile.in" <<'PYEOF'
import re, sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    txt = fh.read()
txt = re.sub(
    r"^libmath\.h:.*?(?=\nsbc\.o:)",
    "libmath.h: libmath.b\n\tcp -f $(srcdir)/libmath.h.prebuilt libmath.h",
    txt,
    flags=re.MULTILINE | re.DOTALL,
)
with open(path, "w", encoding="utf-8") as fh:
    fh.write(txt)
PYEOF

    LIBS="-lreadline -lncursesw -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-readline

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
