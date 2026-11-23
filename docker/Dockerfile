# syntax=docker/dockerfile:1
# Construir com: docker build --platform=linux/amd64 -t bb10-berrycore-builder:latest -f docker/Dockerfile .
# (Em ambientes com proxy TLS customizado, adicione: --secret id=extra_ca,src=/caminho/para/ca.crt)
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TOOLCHAIN_DIR=/opt/bb10-gcc9 \
    TARGET=arm-blackberry-qnx8eabi \
    PREFIX=/accounts/1000/shared/misc/berrycore

# 1. Dependências de host exigidas pela Fase 0 (+ suporte i386 para os binários 32-bit da toolchain BerryCore GCC 9.3.0)
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    libc6:i386 \
    libstdc++6:i386 \
    zlib1g:i386 \
    build-essential \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    bison \
    flex \
    gawk \
    m4 \
    patch \
    git \
    git-lfs \
    curl \
    wget \
    ca-certificates \
    unzip \
    zip \
    xz-utils \
    python3 \
    perl \
    file \
    binutils \
    texinfo \
    jq \
    && rm -rf /var/lib/apt/lists/*

# 2. Atualização global de config.sub e config.guess (GNU) para suporte ao alvo QNX
RUN --mount=type=secret,id=extra_ca,required=false \
    set -eux; \
    if [ -f /run/secrets/extra_ca ]; then \
        cp /run/secrets/extra_ca /usr/local/share/ca-certificates/extra-ca.crt && update-ca-certificates; \
    fi; \
    mkdir -p /usr/share/misc; \
    curl -fsSL "https://git.savannah.gnu.org/cgit/config.git/plain/config.sub" -o /usr/share/misc/config.sub; \
    curl -fsSL "https://git.savannah.gnu.org/cgit/config.git/plain/config.guess" -o /usr/share/misc/config.guess; \
    chmod 755 /usr/share/misc/config.sub /usr/share/misc/config.guess; \
    if [ -f /usr/local/share/ca-certificates/extra-ca.crt ]; then \
        rm -f /usr/local/share/ca-certificates/extra-ca.crt && update-ca-certificates --fresh; \
    fi

# 3. Download e extração da toolchain comunitária BerryCore GCC 9.3.0 (arm-blackberry-qnx8eabi)
#    Usa o endpoint oficial GitHub LFS media (media.githubusercontent.com) para baixar diretamente gcc-9.3.0-qnx8.tar.gz
ARG BERRYCORE_REF=main
ARG TOOLCHAIN_URL=https://media.githubusercontent.com/media/sw7ft/BerryCore/${BERRYCORE_REF}/toolchain/gcc-9.3.0-qnx8.tar.gz
RUN --mount=type=secret,id=extra_ca,required=false \
    set -eux; \
    if [ -f /run/secrets/extra_ca ]; then \
        cp /run/secrets/extra_ca /usr/local/share/ca-certificates/extra-ca.crt && update-ca-certificates; \
    fi; \
    mkdir -p "${TOOLCHAIN_DIR}" /tmp/tc-extract; \
    curl -fsSL --retry 3 --retry-delay 2 "${TOOLCHAIN_URL}" -o /tmp/gcc-9.3.0-qnx8.tar.gz; \
    tar -xzf /tmp/gcc-9.3.0-qnx8.tar.gz -C /tmp/tc-extract; \
    if [ -d /tmp/tc-extract/gcc-9.3.0-berrycore ]; then \
        mv /tmp/tc-extract/gcc-9.3.0-berrycore/* "${TOOLCHAIN_DIR}/"; \
    elif [ -d /tmp/tc-extract/qnx800 ]; then \
        mv /tmp/tc-extract/qnx800/* "${TOOLCHAIN_DIR}/"; \
    else \
        mv /tmp/tc-extract/* "${TOOLCHAIN_DIR}/"; \
    fi; \
    ln -sfn "${TOOLCHAIN_DIR}" /root/qnx800; \
    printf '%s\n%s\n' \
        "${TOOLCHAIN_DIR}/x86_64-linux/arm-blackberry-qnx8eabi/lib64" \
        "${TOOLCHAIN_DIR}/x86_64-linux/arm-blackberry-qnx8eabi/lib" \
        > /etc/ld.so.conf.d/bb10-gcc9.conf; \
    ldconfig; \
    rm -rf /tmp/gcc-9.3.0-qnx8.tar.gz /tmp/tc-extract; \
    if [ -f /usr/local/share/ca-certificates/extra-ca.crt ]; then \
        rm -f /usr/local/share/ca-certificates/extra-ca.crt && update-ca-certificates --fresh; \
    fi

# 4. Variáveis de ambiente da toolchain QNX / BerryCore GCC 9.3.0
ENV PATH="${TOOLCHAIN_DIR}/bin:${PATH}" \
    QNX_VERSION="qnx800" \
    QNX_HOST="${TOOLCHAIN_DIR}/x86_64-linux" \
    QNX_TARGET="${TOOLCHAIN_DIR}" \
    QNX_INC="${TOOLCHAIN_DIR}/include" \
    QNX_ARCH="armle-v7" \
    QNX_ABI="arm-blackberry-qnx8eabi" \
    QNX_BIN="${TOOLCHAIN_DIR}/bin" \
    QNX_PREBUILT="${TOOLCHAIN_DIR}/arm-blackberry-qnx8eabi" \
    QNX_PREBUILT_BIN="${TOOLCHAIN_DIR}/x86_64-linux/arm-blackberry-qnx8eabi/bin" \
    QNX_PREBUILT_LIBEXEC="${TOOLCHAIN_DIR}/x86_64-linux/arm-blackberry-qnx8eabi/lib64" \
    QNX_PREBUILT_GCCLIB="${TOOLCHAIN_DIR}/x86_64-linux/arm-blackberry-qnx8eabi/lib64/gcc/arm-blackberry-qnx8eabi/9.3.0"

WORKDIR /workspace

CMD ["/bin/bash"]
