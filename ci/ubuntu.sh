apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bzip2 \
        clang-10 \
        cmake \
        curl \
        gcc-10 \
        git \
        krb5-user \
        libcurl4-gnutls-dev \
        libgcrypt20-dev \
        libkrb5-dev \
        libpcre3-dev \
        libssl-dev \
        libz-dev \
        llvm-10 \
        make \
        ninja-build \
        openjdk-8-jre-headless \
        openssh-server \
        openssl \
        pkgconf \
        python \
        sudo \
        valgrind \
        && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /usr/local/msan

cd /tmp && \
    curl --location --silent --show-error https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/mbedtls-2.16.2.tar.gz | \
        tar -xz && \
    cd mbedtls-mbedtls-2.16.2 && \
    scripts/config.pl unset MBEDTLS_AESNI_C && \
    scripts/config.pl set MBEDTLS_MD4_C 1 && \
    mkdir build build-msan && \
    cd build && \
    CC=clang-10 CFLAGS="-fPIC" cmake -G Ninja -DENABLE_PROGRAMS=OFF -DENABLE_TESTING=OFF -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DUSE_STATIC_MBEDTLS_LIBRARY=OFF -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=/usr/local -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    ninja install && \
    cd ../build-msan && \
    CC=clang-10 CFLAGS="-fPIC" cmake -G Ninja -DENABLE_PROGRAMS=OFF -DENABLE_TESTING=OFF -DUSE_SHARED_MBEDTLS_LIBRARY=ON -DUSE_STATIC_MBEDTLS_LIBRARY=OFF -DCMAKE_BUILD_TYPE=MemSanDbg -DCMAKE_INSTALL_PREFIX=/usr/local/msan .. && \
    ninja install && \
    cd .. && \
    rm -rf mbedtls-mbedtls-2.16.2

cd /tmp && \
    curl --location --silent --show-error https://www.libssh2.org/download/libssh2-1.9.0.tar.gz | tar -xz && \
    cd libssh2-1.9.0 && \
    mkdir build build-msan && \
    cd build && \
    CC=clang-10 CFLAGS="-fPIC" cmake -G Ninja -DBUILD_SHARED_LIBS=ON -DCRYPTO_BACKEND=Libgcrypt -DCMAKE_PREFIX_PATH=/usr/local -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    ninja install && \
    cd ../build-msan && \
    CC=clang-10 CFLAGS="-fPIC -fsanitize=memory -fno-optimize-sibling-calls -fsanitize-memory-track-origins=2 -fno-omit-frame-pointer" LDFLAGS="-fsanitize=memory" cmake -G Ninja -DBUILD_SHARED_LIBS=ON -DCRYPTO_BACKEND=mbedTLS -DCMAKE_PREFIX_PATH=/usr/local/msan -DCMAKE_INSTALL_PREFIX=/usr/local/msan .. && \
    ninja install && \
    cd .. && \
    rm -rf libssh2-1.9.0

cd /tmp && \
    curl --insecure --location --silent --show-error https://sourceware.org/pub/valgrind/valgrind-3.15.0.tar.bz2 | \
        tar -xj && \
    cd valgrind-3.15.0 && \
    CC=clang-10 ./configure && \
    make MAKEFLAGS="-j -l$(grep -c ^processor /proc/cpuinfo)" && \
    make install && \
    cd .. && \
    rm -rf valgrind-3.15.0

if [ "${UID}" != "" ]; then USER_ARG="--uid ${UID}"; fi && \
    if [ "${GID}" != "" ]; then GROUP_ARG="--gid ${GID}"; fi && \
    groupadd ${GROUP_ARG} libgit2 && \
    useradd ${USER_ARG} --gid libgit2 --shell /bin/bash --create-home libgit2

mkdir /var/run/sshd