# recipes/01-ncurses.sh — Camada 0: ncurses + ncurses-bin (libncursesw, tput, clear, infocmp, terminfo)
PKG_ID="01"
PKG_NAME="ncurses"
PKG_VER="6.5"
PKG_LAYER="0"
PKG_CRITICAL="1"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz"
PKG_SHA256="SKIP"

build() {
    # 1. Compila utilitário nativo 'tic' no host para gerar o banco terminfo sem Exec format error
    local host_build="${BUILD_DIR}/host-tic"
    rm -rf "${host_build}"
    mkdir -p "${host_build}"
    (
        cd "${host_build}"
        env -u CFLAGS -u CXXFLAGS -u CPPFLAGS -u LDFLAGS -u LIBS \
            -u CPP -u AR -u AS -u LD -u RANLIB -u STRIP -u NM \
            -u PKG_CONFIG_LIBDIR -u PKG_CONFIG_SYSROOT_DIR \
            CC="${HOSTCC}" CXX="${HOSTCXX}" \
            "${SRC_DIR}/configure" \
                --without-shared \
                --without-cxx \
                --without-cxx-binding \
                --without-ada \
                --without-manpages \
                --without-tests \
                --enable-widec
        make -j"${JOBS}" -C include
        make -j"${JOBS}" -C ncurses
        make -j"${JOBS}" -C progs tic
    )

    # 2. Compilação cruzada do ncurses wide-char para arm-blackberry-qnx8eabi
    local cross_build="${BUILD_DIR}/cross"
    rm -rf "${cross_build}"
    mkdir -p "${cross_build}"
    cd "${cross_build}"

    ac_cv_header_sys_termio_h=no \
    ac_cv_header_termio_h=no \
    ac_cv_header_search_h=no \
    "${SRC_DIR}/configure" \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-shared \
        --with-normal \
        --without-debug \
        --without-ada \
        --without-cxx \
        --without-cxx-binding \
        --without-tests \
        --without-manpages \
        --enable-widec \
        --disable-ext-colors \
        --enable-pc-files \
        --with-pkg-config-libdir="${PREFIX}/lib/pkgconfig" \
        --with-build-cc="${HOSTCC}" \
        --with-default-terminfo-dir="${PREFIX}/share/terminfo" \
        --with-terminfo-dirs="${PREFIX}/share/terminfo" \
        --disable-stripping

    make -j"${JOBS}"
}

install_staging() {
    local host_tic="${BUILD_DIR}/host-tic/progs/tic"
    cd "${BUILD_DIR}/cross"
    make DESTDIR="${STAGING}" TIC_PATH="${host_tic}" install

    # Links de compatibilidade para consumidores que procuram -lncurses/-lcurses/-ltinfo e <ncurses.h>
    local libdir="${SYSROOT_PREFIX}/lib"
    local incdir="${SYSROOT_PREFIX}/include"
    local pcdir="${libdir}/pkgconfig"

    for base in ncurses form panel menu; do
        if [[ -e "${libdir}/lib${base}w.so" ]]; then
            ln -sf "lib${base}w.so" "${libdir}/lib${base}.so"
        fi
        if [[ -e "${libdir}/lib${base}w.a" ]]; then
            ln -sf "lib${base}w.a" "${libdir}/lib${base}.a"
        fi
        if [[ -e "${pcdir}/${base}w.pc" ]]; then
            ln -sf "${base}w.pc" "${pcdir}/${base}.pc"
        fi
    done
    ln -sf "libncursesw.so" "${libdir}/libcurses.so"
    ln -sf "libncursesw.so" "${libdir}/libtinfo.so"
    ln -sf "libncursesw.so" "${libdir}/libtermcap.so"
    ln -sf "libncursesw.a" "${libdir}/libtermcap.a"

    if [[ -d "${incdir}/ncursesw" ]]; then
        for hdr in curses.h ncurses.h term.h termcap.h unctrl.h panel.h menu.h form.h; do
            if [[ -f "${incdir}/ncursesw/${hdr}" ]]; then
                ln -sf "ncursesw/${hdr}" "${incdir}/${hdr}"
            fi
        done
    fi

    # Remove eventuais caminhos de staging em scripts de config e .pc
    if [[ -f "${SYSROOT_PREFIX}/bin/ncursesw6-config" ]]; then
        sed -i "s|${STAGING}||g" "${SYSROOT_PREFIX}/bin/ncursesw6-config"
    fi
    find "${pcdir}" -name '*.pc' -exec sed -i "s|${STAGING}||g" {} +
    find "${libdir}" -name '*.la' -delete
}
