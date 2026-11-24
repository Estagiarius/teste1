# recipes/52-w3m.sh — Camada 4: w3m (navegador de terminal vinculado a bdwgc, ncurses, openssl)
PKG_ID="52"
PKG_NAME="w3m"
PKG_VER="0.5.3-git20230121"
PKG_LAYER="4"
PKG_CRITICAL="0"
PKG_DEPS="bdwgc ncurses openssl zlib"
PKG_URL="https://github.com/tats/w3m/archive/refs/tags/v0.5.3+git20230121.tar.gz"
PKG_SHA256="SKIP"

build() {
    ac_cv_func_setpgrp_void=yes \
    LIBS="-lsocket -lm" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --with-gc="${SYSROOT_PREFIX}" \
        --with-ssl="${SYSROOT_PREFIX}" \
        --with-termlib=ncursesw \
        --disable-image \
        --disable-nls \
        --disable-mouse \
        --disable-m17n \
        --disable-unicode

    # Compila mktable no host com stub mínimo de gc.h (evita dependência libgc-dev no host e Exec format error)
    local gc_stub="${BUILD_DIR}/host-gc-stub"
    mkdir -p "${gc_stub}"
    cat > "${gc_stub}/gc.h" <<'GCEOF'
#ifndef HOST_GC_STUB_H
#define HOST_GC_STUB_H
#include <stdlib.h>
#include <string.h>
static inline void GC_init(void) {}
static inline void *GC_malloc(size_t n) { return calloc(1, n); }
static inline void *GC_malloc_atomic(size_t n) { return malloc(n); }
static inline void *GC_realloc(void *p, size_t n) { return realloc(p, n); }
static inline void GC_free(void *p) { free(p); }
#define GC_INIT() GC_init()
#define GC_MALLOC(n) GC_malloc((n))
#define GC_MALLOC_ATOMIC(n) GC_malloc_atomic((n))
#define GC_REALLOC(p, n) GC_realloc((p), (n))
#define GC_FREE(p) GC_free((p))
#define GC_STRDUP(s) strdup((s))
#endif
GCEOF
    "${HOSTCC}" -O2 -I. -I"${gc_stub}" -o "${BUILD_DIR}/host-mktable" mktable.c hash.c Str.c myctype.c -lm
    sed -i "s|\./mktable|${BUILD_DIR}/host-mktable|g" Makefile
    make -j"${JOBS}" HOSTCC="${HOSTCC}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
