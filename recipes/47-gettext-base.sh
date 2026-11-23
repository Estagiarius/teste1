# recipes/47-gettext-base.sh — Camada 3: gettext-runtime (envsubst, gettext, ngettext)
PKG_ID="47"
PKG_NAME="gettext-base"
PKG_VER="0.22.5"
PKG_LAYER="3"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/gettext/gettext-0.22.5.tar.xz"
PKG_SHA256="SKIP"

build() {
    cd "${SRC_DIR}/gettext-runtime"
    am_cv_func_iconv=no \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-java \
        --disable-native-java \
        --disable-csharp \
        --disable-c++ \
        --disable-libasprintf \
        --disable-rpath \
        --without-libiconv-prefix \
        --disable-nls \
        --enable-shared \
        --enable-static

    make -j"${JOBS}" CFLAGS="${CFLAGS} -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0"
}

install_staging() {
    cd "${SRC_DIR}/gettext-runtime"
    make DESTDIR="${STAGING}" install
    find "${SYSROOT_PREFIX}/lib" -name 'libintl*.la' -delete
}
