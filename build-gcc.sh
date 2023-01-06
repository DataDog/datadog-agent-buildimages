#!/bin/bash

set -e

GCC_VERSION=8.4.0
GCC_SHA256=41e8b145832fc0b2b34c798ed25fb54a881b0cee4cd581b77c7dc92722c116a8
PREFIX="${PREFIX:-/usr}"

prepare_sources() {
    local archive=$1
    local extension="${archive##*.}"
    local tar_arg

    case $extension in
      xz)
        tar_arg=J
        ;;
      bz2)
        tar_arg=j
        ;;
      gz)
        tar_arg=z
        ;;
      *)
        echo "Unsupported archive format $extension"
        exit 1
        ;;
    esac

    tar xv${tar_arg}f ${archive}
}

compile_with_autoconf() {
    [ -e /etc/redhat-release ] && configure_args="--libdir=$PREFIX/lib64" || true
    ./configure --prefix=$PREFIX $configure_args $*
    cpu_count=$(grep process /proc/cpuinfo | wc -l)
    make -j $cpu_count
    make install
}

url="https://mirrors.kernel.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz"
archive=$(basename $url)
[ ! -e "$archive" ] && curl -LO $url || true
echo "${GCC_SHA256}  ${archive}" | sha256sum --check

prepare_sources $(basename $url)
cd gcc-${GCC_VERSION}

contrib/download_prerequisites --no-isl --no-graphite

compile_with_autoconf \
    --disable-nls \
    --enable-languages=c,c++ \
    --disable-multilib

cd -
