# recipes/07-sqlite3.sh — Camada 0: SQLite3 (amalgamation em C puro; CLI + libsqlite3 para python3)
PKG_ID="07"
PKG_NAME="sqlite3"
PKG_VER="3.47.2"
PKG_LAYER="0"
PKG_CRITICAL="1"
PKG_DEPS="zlib ncurses readline"
PKG_URL="https://www.sqlite.org/2024/sqlite-autoconf-3470200.tar.gz"
PKG_SHA256="SKIP"

build() {
    CFLAGS="${CFLAGS} -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_SECURE_DELETE" \
    LIBS="-lreadline -lncursesw -lz -lm -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --enable-readline \
        --enable-fts5 \
        --enable-shared \
        --enable-static \
        --disable-tcl

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    find "${SYSROOT_PREFIX}/lib" -name 'libsqlite3*.la' -delete
}
