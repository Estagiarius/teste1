# recipes/44-vim.sh — Camada 3: Vim (normal sem GUI, vinculado a ncurses)
PKG_ID="44"
PKG_NAME="vim"
PKG_VER="9.1.1000"
PKG_LAYER="3"
PKG_CRITICAL="0"
PKG_DEPS="ncurses"
PKG_URL="https://github.com/vim/vim/archive/refs/tags/v9.1.1000.tar.gz"
PKG_SHA256="SKIP"

build() {
    vim_cv_toupper_broken=no \
    vim_cv_terminfo=yes \
    vim_cv_tty_group=world \
    vim_cv_tty_mode=0620 \
    vim_cv_getcwd_broken=no \
    vim_cv_stat_ignores_slash=no \
    vim_cv_memmove_handles_overlap=yes \
    vim_cv_bcopy_handles_overlap=yes \
    vim_cv_memcpy_handles_overlap=yes \
    vim_cv_tgetent=non-zero \
    ac_cv_sizeof_int=4 \
    ac_cv_small_wchar_t=no \
    ac_cv_search_iconv_open=no \
    ac_cv_header_iconv_h=no \
    LIBS="-lncursesw -lsocket -lm" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-features=normal \
        --disable-gui \
        --without-x \
        --disable-nls \
        --disable-iconv \
        --disable-gpm \
        --disable-sysmouse \
        --disable-selinux \
        --disable-smack \
        --disable-canberra \
        --disable-libsodium \
        --with-tlib=ncursesw

    make -j"${JOBS}" STRIP=true
}

install_staging() {
    make DESTDIR="${STAGING}" STRIP=true install
}
