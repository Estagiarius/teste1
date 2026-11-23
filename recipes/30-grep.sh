# recipes/30-grep.sh — Camada 2: GNU grep vinculado a PCRE2
PKG_ID="30"
PKG_NAME="grep"
PKG_VER="3.11"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS="pcre2"
PKG_URL="https://ftp.gnu.org/gnu/grep/grep-3.11.tar.xz"
PKG_SHA256="SKIP"

build() {
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --enable-perl-regexp \
        --disable-nls

    make -j"${JOBS}" CFLAGS="${CFLAGS} -include sys/time.h -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0"
}

install_staging() {
    make DESTDIR="${STAGING}" install
    for script in egrep fgrep; do
        if [[ -f "${SYSROOT_PREFIX}/bin/${script}" ]]; then
            sed -i "s|${STAGING}||g" "${SYSROOT_PREFIX}/bin/${script}"
        fi
    done
}
