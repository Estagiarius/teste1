# recipes/64-git.sh — Camada 5 (Pocket Laptop CLI): Git (vinculado a openssl, curl, zlib e expat)
PKG_ID="64"
PKG_NAME="git"
PKG_VER="2.47.1"
PKG_LAYER="5"
PKG_CRITICAL="0"
PKG_DEPS="zlib openssl curl expat"
PKG_URL="https://www.kernel.org/pub/software/scm/git/git-2.47.1.tar.xz"
PKG_SHA256="SKIP"

build() {
    local git_make_args=(
        CC="${CC}"
        AR="${AR}"
        CFLAGS="${CFLAGS} -DSA_RESTART=0 -D__LITTLE_ENDIAN=1234 -D__BIG_ENDIAN=4321 -D__BYTE_ORDER=1234"
        LDFLAGS="${LDFLAGS}"
        EXTLIBS="-lcurl -lnghttp2 -lssl -lcrypto -lz -lsocket"
        CURL_CONFIG="${SYSROOT_PREFIX}/bin/curl-config"
        prefix="${PREFIX}"
        SHELL_PATH="/bin/sh"
        PERL_PATH="/usr/bin/perl"
        NO_TCLTK=1
        NO_GETTEXT=1
        NO_PYTHON=1
        NO_PERL=1
        NO_INSTALL_HARDLINKS=1
        NO_ICONV=1
        NO_EXPAT=1
        NO_REGEX=YesPlease
        NO_PTHREADS=YesPlease
        NO_MMAP=YesPlease
        NO_NSEC=YesPlease
        FREAD_READS_DIRECTORIES=UnfortunatelyYes
        SNPRINTF_RETURNS_BOGUS=UnfortunatelyYes
        HOST_CPU=arm
        uname_S=QNX
        uname_M=armle-v7
        uname_R=6.6.0
    )

    make -j"${JOBS}" "${git_make_args[@]}" \
        git git-remote-http git-http-fetch git-shell git-daemon git-http-backend git-imap-send
}

install_staging() {
    local git_make_args=(
        CC="${CC}"
        AR="${AR}"
        CFLAGS="${CFLAGS} -DSA_RESTART=0 -D__LITTLE_ENDIAN=1234 -D__BIG_ENDIAN=4321 -D__BYTE_ORDER=1234"
        LDFLAGS="${LDFLAGS}"
        EXTLIBS="-lcurl -lnghttp2 -lssl -lcrypto -lz -lsocket"
        CURL_CONFIG="${SYSROOT_PREFIX}/bin/curl-config"
        prefix="${PREFIX}"
        SHELL_PATH="/bin/sh"
        NO_TCLTK=1
        NO_GETTEXT=1
        NO_PYTHON=1
        NO_PERL=1
        NO_INSTALL_HARDLINKS=1
        NO_ICONV=1
        NO_EXPAT=1
        NO_REGEX=YesPlease
        NO_PTHREADS=YesPlease
        NO_MMAP=YesPlease
        NO_NSEC=YesPlease
        FREAD_READS_DIRECTORIES=UnfortunatelyYes
        SNPRINTF_RETURNS_BOGUS=UnfortunatelyYes
        HOST_CPU=arm
        uname_S=QNX
        uname_M=armle-v7
        uname_R=6.6.0
    )

    make DESTDIR="${STAGING}" "${git_make_args[@]}" install
}
