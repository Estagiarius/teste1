# recipes/22-gzip.sh — Camada 2: GNU gzip
PKG_ID="22"
PKG_NAME="gzip"
PKG_VER="1.13"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/gzip/gzip-1.13.tar.xz"
PKG_SHA256="SKIP"

build() {
    ac_cv_func_stpcpy=no \
    CFLAGS="${CFLAGS} -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -fno-builtin-stpcpy" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}"

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    for script in gunzip gzexe uncompress zcat zcmp zdiff zegrep zfgrep zforce zgrep zless zmore znew; do
        if [[ -f "${SYSROOT_PREFIX}/bin/${script}" ]]; then
            sed -i "s|${STAGING}||g" "${SYSROOT_PREFIX}/bin/${script}"
        fi
    done
}
