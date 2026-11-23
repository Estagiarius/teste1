#!/usr/bin/env bash
# scripts/env-cross.sh — Ambiente padrão de compilação cruzada Debian-to-BerryCore (QNX Neutrino / BlackBerry Q5)
# Deve ser carregado via: source scripts/env-cross.sh

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERRO: Execute este script via 'source scripts/env-cross.sh'" >&2
    exit 1
fi

export TARGET="arm-blackberry-qnx8eabi"
export BUILD_TRIPLE="${BUILD_TRIPLE:-x86_64-pc-linux-gnu}"
export WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
export TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-/opt/bb10-gcc9}"

export PREFIX="/accounts/1000/shared/misc/berrycore"
export STAGING="${STAGING:-${WORKSPACE_ROOT}/staging}"
export SYSROOT_PREFIX="${STAGING}${PREFIX}"

# Variáveis da toolchain QNX / BerryCore GCC 9.3.0
export QNX_VERSION="${QNX_VERSION:-qnx800}"
export QNX_HOST="${QNX_HOST:-${TOOLCHAIN_DIR}/x86_64-linux}"
export QNX_TARGET="${QNX_TARGET:-${TOOLCHAIN_DIR}}"
export QNX_INC="${QNX_INC:-${TOOLCHAIN_DIR}/include}"
export QNX_ARCH="${QNX_ARCH:-armle-v7}"
export QNX_ABI="${QNX_ABI:-${TARGET}}"
export QNX_BIN="${QNX_BIN:-${TOOLCHAIN_DIR}/bin}"
export QNX_PREBUILT="${QNX_PREBUILT:-${TOOLCHAIN_DIR}/${TARGET}}"
export QNX_PREBUILT_BIN="${QNX_PREBUILT_BIN:-${QNX_HOST}/${TARGET}/bin}"
export QNX_PREBUILT_LIBEXEC="${QNX_PREBUILT_LIBEXEC:-${QNX_HOST}/${TARGET}/lib64}"
export QNX_PREBUILT_GCCLIB="${QNX_PREBUILT_GCCLIB:-${QNX_PREBUILT_LIBEXEC}/gcc/${TARGET}/9.3.0}"

# Garante que os binários da toolchain tenham prioridade no PATH sem duplicar entradas
case ":${PATH}:" in
    *":${TOOLCHAIN_DIR}/bin:"*) ;;
    *) export PATH="${TOOLCHAIN_DIR}/bin:${PATH}" ;;
esac

# Ferramentas de compilação cruzada (target: arm-blackberry-qnx8eabi)
export CC="${TOOLCHAIN_DIR}/bin/${TARGET}-gcc"
export CXX="${TOOLCHAIN_DIR}/bin/${TARGET}-g++"
export CPP="${TOOLCHAIN_DIR}/bin/${TARGET}-gcc -E"
export AR="${TOOLCHAIN_DIR}/bin/${TARGET}-ar"
export AS="${TOOLCHAIN_DIR}/bin/${TARGET}-as"
export LD="${TOOLCHAIN_DIR}/bin/${TARGET}-ld"
export RANLIB="${TOOLCHAIN_DIR}/bin/${TARGET}-ranlib"
export STRIP="${TOOLCHAIN_DIR}/bin/${TARGET}-strip"
export NM="${TOOLCHAIN_DIR}/bin/${TARGET}-nm"
export READELF="${TOOLCHAIN_DIR}/bin/${TARGET}-readelf"
export OBJCOPY="${TOOLCHAIN_DIR}/bin/${TARGET}-objcopy"
export OBJDUMP="${TOOLCHAIN_DIR}/bin/${TARGET}-objdump"

# Compiladores nativos do host (para ferramentas auxiliares de build como tic, file, mktable, build-python)
export HOSTCC="${HOSTCC:-gcc}"
export HOSTCXX="${HOSTCXX:-g++}"
export CC_FOR_BUILD="${CC_FOR_BUILD:-gcc}"
export CXX_FOR_BUILD="${CXX_FOR_BUILD:-g++}"

# Isolamento estrito de pkg-config (impede leitura de bibliotecas do Linux host)
unset PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR="${SYSROOT_PREFIX}/lib/pkgconfig:${SYSROOT_PREFIX}/share/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR="${STAGING}"

# Flags de compilação e linkagem padrão apontando exclusivamente para ${SYSROOT_PREFIX} e RPATH ${PREFIX}/lib
export CFLAGS="-O2 -pipe -I${SYSROOT_PREFIX}/include"
export CXXFLAGS="-O2 -pipe -I${SYSROOT_PREFIX}/include"
export CPPFLAGS="-I${SYSROOT_PREFIX}/include"
export LDFLAGS="-L${SYSROOT_PREFIX}/lib -Wl,-rpath,${PREFIX}/lib -lsocket"

# Paralelismo padrão de build
if command -v nproc >/dev/null 2>&1; then
    export JOBS="${JOBS:-$(nproc)}"
else
    export JOBS="${JOBS:-2}"
fi

# Inicializa árvore base do sysroot de staging quando gravável
mkdir -p \
    "${SYSROOT_PREFIX}/bin" \
    "${SYSROOT_PREFIX}/sbin" \
    "${SYSROOT_PREFIX}/lib/pkgconfig" \
    "${SYSROOT_PREFIX}/include" \
    "${SYSROOT_PREFIX}/share/pkgconfig" \
    "${SYSROOT_PREFIX}/etc/ssl/certs"
