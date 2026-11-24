# recipes/32-coreutils.sh — Camada 2: GNU coreutils (modo cross com variáveis fu_cv_* e sem subcomandos Linux/SELinux)
PKG_ID="32"
PKG_NAME="coreutils"
PKG_VER="9.5"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/coreutils/coreutils-9.5.tar.xz"
PKG_SHA256="SKIP"

build() {
    local qnx_gnulib_cflags="-DSA_RESTART=0 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -DUCHAR_WIDTH=8 -DSCHAR_WIDTH=8 -DCHAR_WIDTH=8 -DSHRT_WIDTH=16 -DUSHRT_WIDTH=16 -DINT_WIDTH=32 -DUINT_WIDTH=32 -DLONG_WIDTH=32 -DULONG_WIDTH=32 -DLLONG_WIDTH=64 -DULLONG_WIDTH=64 -DUINTPTR_WIDTH=32 -DINTPTR_WIDTH=32 -DSIZE_WIDTH=32"
    FORCE_UNSAFE_CONFIGURE=1 \
    am_cv_func_iconv=no \
    ac_list_mounted_fs=found \
    fu_cv_sys_mounted_fread=yes \
    fu_cv_sys_stat_statfs2_bsize=yes \
    gl_cv_func_working_mkstemp=yes \
    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_realloc_0_nonnull=yes \
    CFLAGS="${CFLAGS} ${qnx_gnulib_cflags}" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --without-libiconv-prefix \
        --disable-nls \
        --disable-acl \
        --disable-xattr \
        --without-selinux \
        --without-gmp \
        --without-openssl \
        --enable-no-install-program=chcon,runcon,stdbuf,kill,uptime,df,pinky,users,who,nice

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
