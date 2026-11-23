# recipes/46-time.sh — Camada 3: GNU time
PKG_ID="46"
PKG_NAME="time"
PKG_VER="1.9"
PKG_LAYER="3"
PKG_CRITICAL="0"
PKG_DEPS=""
PKG_URL="https://ftp.gnu.org/gnu/time/time-1.9.tar.gz"
PKG_SHA256="SKIP"

build() {
    ./configure \
        --build="${BUILD_TRIPLE}" \
        --host="${TARGET}" \
        --prefix="${PREFIX}"

    make -j"${JOBS}" CFLAGS="${CFLAGS} -include sys/time.h -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0"
}

install_staging() {
    make DESTDIR="${STAGING}" install
}
