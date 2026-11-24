# recipes/31-findutils.sh — Camada 2: GNU findutils (find, xargs)
PKG_ID="31"
PKG_NAME="findutils"
PKG_VER="4.10.0"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz"
PKG_SHA256="SKIP"

build() {
    local qnx_gnulib_cflags="-DSA_RESTART=0 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -DUCHAR_WIDTH=8 -DSCHAR_WIDTH=8 -DCHAR_WIDTH=8 -DSHRT_WIDTH=16 -DUSHRT_WIDTH=16 -DINT_WIDTH=32 -DUINT_WIDTH=32 -DLONG_WIDTH=32 -DULONG_WIDTH=32 -DLLONG_WIDTH=64 -DULLONG_WIDTH=64 -DUINTPTR_WIDTH=32 -DINTPTR_WIDTH=32 -DSIZE_WIDTH=32"
    am_cv_func_iconv=no \
    ac_list_mounted_fs=found \
    fu_cv_sys_mounted_fread=yes \
    CFLAGS="${CFLAGS} ${qnx_gnulib_cflags}" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --localstatedir="${PREFIX}/var" \
        --without-libiconv-prefix \
        --disable-nls \
        --without-selinux

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
