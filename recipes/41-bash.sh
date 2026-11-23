# recipes/41-bash.sh — Camada 3: GNU Bash vinculado a readline e ncurses
PKG_ID="41"
PKG_NAME="bash"
PKG_VER="5.2.37"
PKG_LAYER="3"
PKG_CRITICAL="0"
PKG_DEPS="ncurses readline"
PKG_URL="https://ftp.gnu.org/gnu/bash/bash-5.2.37.tar.gz"
PKG_SHA256="SKIP"

build() {
    bash_cv_wcwidth_broken=no \
    bash_cv_func_sigsetjmp=present \
    bash_cv_getenv_redef=yes \
    bash_cv_job_control_missing=present \
    bash_cv_sys_named_pipes=present \
    bash_cv_must_reinstall_sighandlers=no \
    bash_cv_ulimit_maxfds=yes \
    bash_cv_getcwd_malloc=yes \
    ac_cv_func_working_mktime=yes \
    LIBS="-lncursesw -lsocket" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-installed-readline="${SYSROOT_PREFIX}" \
        --without-bash-malloc \
        --disable-nls \
        --enable-readline \
        --enable-history

    make -j"${JOBS}" CC_FOR_BUILD="${HOSTCC}" LOCAL_CFLAGS="" LOCAL_LDFLAGS="" LIBS_FOR_BUILD=""
}

install_staging() {
    make DESTDIR="${STAGING}" install
    rm -f "${SYSROOT_PREFIX}/bin/bashbug"
}
