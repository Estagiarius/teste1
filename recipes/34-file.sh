# recipes/34-file.sh — Camada 2: file + libmagic (compila versão host primeiro para gerar magic.mgc)
PKG_ID="34"
PKG_NAME="file"
PKG_VER="5.46"
PKG_LAYER="2"
PKG_CRITICAL="0"
PKG_DEPS="zlib bzip2 xz-utils"
PKG_URL="https://astron.com/pub/file/file-5.46.tar.gz"
PKG_SHA256="SKIP"

build() {
    # 1. Compila versão nativa do host para gerar o banco binário magic.mgc sem Exec format error
    local host_build="${BUILD_DIR}/host-file"
    rm -rf "${host_build}"
    mkdir -p "${host_build}"
    (
        cd "${host_build}"
        env -u CFLAGS -u CXXFLAGS -u CPPFLAGS -u LDFLAGS -u LIBS \
            -u CPP -u AR -u AS -u LD -u RANLIB -u STRIP -u NM \
            -u PKG_CONFIG_LIBDIR -u PKG_CONFIG_SYSROOT_DIR \
            CC="${HOSTCC}" \
            "${SRC_DIR}/configure" \
                --disable-shared \
                --enable-static \
                --disable-libseccomp
        make -j"${JOBS}"
    )

    # 2. Compilação cruzada do file + libmagic usando o executável host como FILE_COMPILE
    local cross_build="${BUILD_DIR}/cross-file"
    rm -rf "${cross_build}"
    mkdir -p "${cross_build}"
    cd "${cross_build}"

    "${SRC_DIR}/configure" \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-libseccomp \
        --enable-shared \
        --enable-static

    make -j"${JOBS}" FILE_COMPILE="${host_build}/src/file"
}

install_staging() {
    cd "${BUILD_DIR}/cross-file"
    make DESTDIR="${STAGING}" FILE_COMPILE="${BUILD_DIR}/host-file/src/file" install
    find "${SYSROOT_PREFIX}/lib" -name 'libmagic*.la' -delete
    find "${SYSROOT_PREFIX}/lib/pkgconfig" -name 'libmagic*.pc' -exec sed -i "s|${STAGING}||g" {} +
}
