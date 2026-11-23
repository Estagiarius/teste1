# Construir com: docker build --platform=linux/amd64 -t bb10-berrycore-builder:latest -f docker/Dockerfile .
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TOOLCHAIN_DIR=/opt/bb10-gcc9 \
    TARGET=arm-blackberry-qnx8eabi \
    PREFIX=/accounts/1000/shared/misc/berrycore

# 1. Dependências de host exigidas pela Fase 0
RUN apt-get update && apt-get install -y --no-install-recommends \
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
RUN mkdir -p /usr/share/misc && \
    curl -fsSL "https://git.savannah.gnu.org/cgit/config.git/plain/config.sub" -o /usr/share/misc/config.sub && \
    curl -fsSL "https://git.savannah.gnu.org/cgit/config.git/plain/config.guess" -o /usr/share/misc/config.guess && \
    chmod 755 /usr/share/misc/config.sub /usr/share/misc/config.guess

# 3. Download e extração da toolchain comunitária BerryCore GCC 9.3.0 (arm-blackberry-qnx8eabi)
#    Usa sparse-checkout + git-lfs para baixar apenas toolchain/gcc-9.3.0-qnx8.tar.gz
ARG BERRYCORE_REPO=https://github.com/sw7ft/BerryCore.git
ARG BERRYCORE_REF=main
RUN set -eux; \
    git lfs install --skip-repo; \
    git clone --depth 1 --branch "${BERRYCORE_REF}" --filter=blob:none --sparse "${BERRYCORE_REPO}" /tmp/berrycore; \
    git -C /tmp/berrycore sparse-checkout set toolchain/gcc-9.3.0-qnx8.tar.gz toolchain/environment_and_docs_20251026.tar.gz; \
    git -C /tmp/berrycore lfs pull --include="toolchain/gcc-9.3.0-qnx8.tar.gz,toolchain/environment_and_docs_20251026.tar.gz"; \
    mkdir -p "${TOOLCHAIN_DIR}" /tmp/tc-extract; \
    tar -xzf /tmp/berrycore/toolchain/gcc-9.3.0-qnx8.tar.gz -C /tmp/tc-extract; \
    if [ -d /tmp/tc-extract/qnx800 ]; then \
        mv /tmp/tc-extract/qnx800/* "${TOOLCHAIN_DIR}/"; \
    else \
        mv /tmp/tc-extract/* "${TOOLCHAIN_DIR}/"; \
    fi; \
    rm -rf /tmp/berrycore /tmp/tc-extract

# 4. Opcional: caso o usuário forneça arquivos proprietários do BB10 NDK / QNX sysroot
#    (libc.so.3, libsocket.so.3 e headers QNX) em docker/sysroot/ antes do build,
#    copie-os para dentro de ${TOOLCHAIN_DIR} mantendo isolamento no contêiner.
#    Consulte sw7ft/BerryCore/toolchain/README.md sobre licenciamento do BB10 NDK.
ENV PATH="${TOOLCHAIN_DIR}/bin:${PATH}" \
    QNX_HOST="${TOOLCHAIN_DIR}/x86_64-linux" \
    QNX_TARGET="${TOOLCHAIN_DIR}/arm-blackberry-qnx8eabi"

WORKDIR /workspace

CMD ["/bin/bash"]
