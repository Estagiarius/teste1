# recipes/26-diffutils.sh — Camada 2: GNU diffutils (diff, cmp, diff3, sdiff)
PKG_ID="26"
PKG_NAME="diffutils"
PKG_VER="3.10"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/diffutils/diffutils-3.10.tar.xz"
PKG_SHA256="SKIP"

build() {
    local qnx_gnulib_cflags="-DSA_RESTART=0 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -DUCHAR_WIDTH=8 -DSCHAR_WIDTH=8 -DCHAR_WIDTH=8 -DSHRT_WIDTH=16 -DUSHRT_WIDTH=16 -DINT_WIDTH=32 -DUINT_WIDTH=32 -DLONG_WIDTH=32 -DULONG_WIDTH=32 -DLLONG_WIDTH=64 -DULLONG_WIDTH=64 -DUINTPTR_WIDTH=32 -DINTPTR_WIDTH=32 -DSIZE_WIDTH=32"
    am_cv_func_iconv=no \
    CFLAGS="${CFLAGS} ${qnx_gnulib_cflags}" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --without-libiconv-prefix \
        --disable-nls

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
