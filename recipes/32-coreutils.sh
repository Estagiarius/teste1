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
    FORCE_UNSAFE_CONFIGURE=1 \
    fu_cv_sys_stat_statfs2_bsize=yes \
    gl_cv_func_working_mkstemp=yes \
    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_realloc_0_nonnull=yes \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-nls \
        --disable-acl \
        --disable-xattr \
        --without-selinux \
        --without-gmp \
        --without-openssl \
        --enable-no-install-program=chcon,runcon,stdbuf,kill,uptime,df,pinky,users,who

    make -j"${JOBS}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
