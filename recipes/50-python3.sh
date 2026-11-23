# recipes/50-python3.sh — Camada 4: Python 3.12.8 (build-python host + cross ARMv7le QNX)
PKG_ID="50"
PKG_NAME="python3"
PKG_VER="3.12.8"
PKG_LAYER="4"
PKG_CRITICAL="0"
PKG_DEPS="openssl zlib libffi sqlite3 ncurses readline bzip2 xz-utils expat"
PKG_URL="https://www.python.org/ftp/python/3.12.8/Python-3.12.8.tar.xz"
PKG_SHA256="SKIP"

build() {
    # 1. Compila Python da exata mesma versão (3.12.8) para o host Linux em /tmp/build/python3-host
    local host_build="/tmp/build/python3-host"
    rm -rf "${host_build}"
    mkdir -p "${host_build}"
    (
        cd "${host_build}"
        unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LIBS CPP AR AS LD RANLIB STRIP NM PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR
        CC="${HOSTCC}" CXX="${HOSTCXX}" \
        "${SRC_DIR}/configure" \
            --disable-test-modules
        make -j"${JOBS}" python
    )

    # 2. Compilação cruzada do Python 3.12.8 para arm-blackberry-qnx8eabi
    local cross_build="${BUILD_DIR}/cross-python3"
    rm -rf "${cross_build}"
    mkdir -p "${cross_build}"
    cd "${cross_build}"

    ac_cv_file__dev_ptmx=yes \
    ac_cv_file__dev_ptc=no \
    ac_cv_buggy_getaddrinfo=no \
    ac_cv_have_long_long_format=yes \
    ac_cv_working_tzset=yes \
    ac_cv_func_getentropy=no \
    ac_cv_header_linux_random_h=no \
    ac_cv_header_sys_epoll_h=no \
    ac_cv_func_epoll_create=no \
    ac_cv_func_epoll_create1=no \
    ac_cv_func_sigaltstack=no \
    CFLAGS="${CFLAGS} -DSA_ONSTACK=0 -DSA_RESTART=0" \
    PKG_CONFIG_LIBDIR="${SYSROOT_PREFIX}/lib/pkgconfig:${SYSROOT_PREFIX}/share/pkgconfig" \
    LIBS="-lsocket -lm" \
    "${SRC_DIR}/configure" \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-build-python="${host_build}/python" \
        --with-openssl="${SYSROOT_PREFIX}" \
        --with-system-expat \
        --with-system-ffi \
        --enable-shared \
        --without-ensurepip \
        --disable-test-modules \
        --disable-ipv6

    make -j"${JOBS}"
}

install_staging() {
    cd "${BUILD_DIR}/cross-python3"
    make DESTDIR="${STAGING}" install
    # Sanitiza possíveis referências a staging em scripts python3-config e .pc
    for f in "${SYSROOT_PREFIX}/bin/python3.12-config" "${SYSROOT_PREFIX}/bin/python3-config"; do
        if [[ -f "${f}" && ! -L "${f}" ]]; then
            sed -i "s|${STAGING}||g" "${f}"
        fi
    done
    find "${SYSROOT_PREFIX}/lib/pkgconfig" -name 'python*.pc' -exec sed -i "s|${STAGING}||g" {} +
}
