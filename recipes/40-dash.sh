# recipes/40-dash.sh — Camada 3: dash (shell POSIX ultrarrápido com CC_FOR_BUILD=gcc)
PKG_ID="40"
PKG_NAME="dash"
PKG_VER="0.5.12"
PKG_LAYER="3"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="http://gondor.apana.org.au/~herbert/dash/files/dash-0.5.12.tar.gz"
PKG_SHA256="SKIP"

build() {
    CC_FOR_BUILD="${HOSTCC}" \
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}" \
        --disable-fnmatch \
        --disable-glob

    make -j"${JOBS}" CC_FOR_BUILD="${HOSTCC}"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
