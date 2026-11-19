#!/usr/bin/env bash
#
# build-aix-cross.sh
#
# Build a Linux-hosted cross-compiler that targets IBM AIX on PowerPC
# (powerpc-ibm-aixX.Y.Z.W), using GNU binutils + GCC.
#
# crosstool-ng cannot build this (it only knows the linux/windows/bare-metal
# kernels and free libcs), so this is a hand-rolled binutils+GCC build.
#
# What this script CAN download:
#   - GNU binutils and GCC sources, cloned from our git forks, which carry
#     the AIX fixes on top of upstream releases
#   - GCC's in-tree prerequisites (GMP / MPFR / MPC / ISL) via
#     contrib/download_prerequisites
#
# What this script CANNOT download (proprietary, must be supplied by you):
#   - The AIX sysroot: AIX headers (/usr/include) and libraries
#     (/usr/lib, /lib: libc.a, crt0*.o, etc.). These come from a licensed
#     AIX install. Point --sysroot at a copy of them. See bottom of file for
#     how to harvest one from a real AIX box.
#
# Build stages:
#   1. binutils  -> always builds (assembler/linker, with XCOFF support)
#   2. gcc 'all-gcc' (the compiler itself) -> always builds
#   3. gcc libgcc + install -> only if a sysroot is provided, because libgcc
#      needs the AIX C library and crt files to link.
#
set -euo pipefail

# --------------------------------------------------------------------------
# Configuration (override via environment or flags)
# --------------------------------------------------------------------------
# GCC stays on 13.x to match the GCC 13 runtime (libstdc++, libgcc) that IBM's
# AIX Toolbox installs on the target machines.
BINUTILS_GIT_URL="${BINUTILS_GIT_URL:-https://github.com/chouquette/binutils-gdb.git}"
BINUTILS_GIT_REF="${BINUTILS_GIT_REF:-datadog-aix-binutils-2.47-1}"
GCC_GIT_URL="${GCC_GIT_URL:-https://github.com/chouquette/gcc.git}"
GCC_GIT_REF="${GCC_GIT_REF:-datadog-aix-gcc-13.5.0-1}"

# AIX release you target. Becomes the OS part of the target triplet.
# Use the version of the AIX system your sysroot came from (e.g. 7.2.0.0,
# 7.3.0.0). GCC/binutils are lenient about the exact value.
AIX_VERSION="${AIX_VERSION:-7.3.0.0}"
TARGET="powerpc-ibm-aix${AIX_VERSION}"

# Directories
ROOT_DIR="${ROOT_DIR:-$PWD/aix-cross}"
SRC_DIR="${SRC_DIR:-$ROOT_DIR/src}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
PREFIX="${PREFIX:-$ROOT_DIR/install}"
SYSROOT="${SYSROOT:-}"        # MUST be set for the libc/install stage

JOBS="${JOBS:-$(nproc)}"

# --------------------------------------------------------------------------
# Arg parsing
# --------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $0 [options]

Builds a powerpc-ibm-aix cross-compiler on Linux.

Options:
  --sysroot PATH        AIX sysroot (headers + libs). Required to build
                        libgcc and finish the toolchain. Accepts either an
                        already-extracted directory OR a tarball harvested
                        from an AIX box (.tar/.tar.gz/.tgz/.tar.Z) — a
                        tarball is extracted and its root auto-located.
                        If omitted, only binutils and the bare compiler
                        (all-gcc) build.
  --prefix PATH         Install prefix          (default: $PREFIX)
  --aix-version V       AIX version for triplet (default: $AIX_VERSION)
  --binutils-ref REF    binutils git tag/branch (default: $BINUTILS_GIT_REF)
  --gcc-ref REF         GCC git tag/branch      (default: $GCC_GIT_REF)
  --jobs N              Parallel make jobs       (default: $JOBS)
  -h, --help            Show this help

All options also accept the matching UPPER_CASE environment variable.

Resulting compiler: \$PREFIX/bin/${TARGET}-gcc
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --sysroot)          SYSROOT="$2"; shift 2 ;;
        --prefix)           PREFIX="$2"; shift 2 ;;
        --aix-version)      AIX_VERSION="$2"; TARGET="powerpc-ibm-aix${AIX_VERSION}"; shift 2 ;;
        --binutils-ref)     BINUTILS_GIT_REF="$2"; shift 2 ;;
        --gcc-ref)          GCC_GIT_REF="$2"; shift 2 ;;
        --jobs)             JOBS="$2"; shift 2 ;;
        -h|--help)          usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# --------------------------------------------------------------------------
# Preflight: required host tools
# --------------------------------------------------------------------------
log "Checking host build tools"
missing=()
for t in gcc g++ make flex bison makeinfo m4 gawk curl tar git; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
done
[ ${#missing[@]} -eq 0 ] || die "Missing host tools: ${missing[*]}"

mkdir -p "$SRC_DIR" "$BUILD_DIR" "$PREFIX"

# --------------------------------------------------------------------------
# Resolve --sysroot: if it points to a tarball, extract it and auto-locate
# the real sysroot root (the dir containing usr/include), regardless of any
# wrapper directory inside the archive.
# --------------------------------------------------------------------------
if [ -n "$SYSROOT" ] && [ -f "$SYSROOT" ]; then
    tarball="$SYSROOT"
    dest="$ROOT_DIR/sysroot"
    log "Sysroot argument is a file; extracting tarball: $tarball"
    rm -rf "$dest"; mkdir -p "$dest"
    # GNU tar auto-detects gzip/xz/bzip2/compress, so plain -xf covers them all.
    tar -xf "$tarball" -C "$dest" || die "Failed to extract sysroot tarball: $tarball"
    inc="$(find "$dest" -type d -path '*/usr/include' -print -quit 2>/dev/null || true)"
    if [ -n "$inc" ]; then
        SYSROOT="$(cd "$inc/../.." && pwd)"
    else
        warn "Could not find usr/include inside $tarball; using extraction dir as-is."
        SYSROOT="$dest"
    fi
    log "Using extracted sysroot: $SYSROOT"
fi

# --------------------------------------------------------------------------
# Normalize sysroot symlinks. AIX headers/libs are full of ABSOLUTE symlinks
# (e.g. /usr/include/stdint.h -> /usr/include/sys/stdint.h). Harvested onto a
# Linux host they dangle (they resolve against the Linux /), which breaks the
# compiler (#include_next <stdint.h> -> "No such file or directory"). Retarget
# every absolute symlink to point INSIDE the sysroot, as a relative link, when
# the target was actually harvested. Links to paths not harvested (X11, pmapi,
# rsct, optional libs) are left as-is — they aren't needed to build the
# toolchain. Idempotent: safe to re-run.
# --------------------------------------------------------------------------
if [ -n "$SYSROOT" ] && [ -d "$SYSROOT" ]; then
    # AIX files/dirs carry restrictive perms (many mode 0600, read-only dirs)
    # that survive cp -p / tar and make the sysroot hard to manage or clean
    # (a non-writable dir blocks rm -rf of its contents). Make it writable.
    log "Making sysroot writable (AIX perms can be restrictive)"
    chmod -R u+rwX "$SYSROOT" 2>/dev/null || true

    log "Normalizing absolute symlinks inside sysroot"
    fixed=0
    while IFS= read -r link; do
        tgt="$(readlink "$link")"
        case "$tgt" in
            /*) newtgt="$SYSROOT$tgt"
                if [ -e "$newtgt" ]; then ln -sfnr "$newtgt" "$link"; fixed=$((fixed+1)); fi ;;
        esac
    done < <(find "$SYSROOT" -type l 2>/dev/null)
    log "Retargeted $fixed absolute symlink(s) into the sysroot"

    # The linker only searches <sysroot>/usr/lib (and /lib), but on AIX the
    # real archives live in /usr/ccs/lib. Mirror them into /usr/lib as
    # relative symlinks for anything not already present, so libc.a & friends
    # are found. (This is how a real AIX /usr/lib looks.)
    if [ -d "$SYSROOT/usr/ccs/lib" ]; then
        added=0
        while IFS= read -r f; do
            b="$(basename "$f")"
            if [ ! -e "$SYSROOT/usr/lib/$b" ]; then
                ln -sfnr "$f" "$SYSROOT/usr/lib/$b" && added=$((added+1))
            fi
        done < <(find "$SYSROOT/usr/ccs/lib" -maxdepth 1 \( -name '*.a' -o -name '*.o' -o -name '*.so' \) 2>/dev/null)
        log "Mirrored $added /usr/ccs/lib archive(s) into /usr/lib"
    else
        warn "No usr/ccs/lib in sysroot — libc.a etc. may be unresolved; see harvest notes."
    fi
fi

# --------------------------------------------------------------------------
# 1. Fetch sources
# --------------------------------------------------------------------------
clone() {
    local url="$1" ref="$2" dir="$3"
    if [ -d "$dir/.git" ]; then
        log "Already cloned: $(basename "$dir")"
        return 0
    fi
    log "Cloning $url ($ref)"
    rm -rf "$dir.part"
    git clone --quiet --depth 1 --branch "$ref" "$url" "$dir.part" || die "Clone failed: $url ($ref)"
    mv "$dir.part" "$dir"
}

BINUTILS_SRC="$SRC_DIR/binutils"
GCC_SRC="$SRC_DIR/gcc"
clone "$BINUTILS_GIT_URL" "$BINUTILS_GIT_REF" "$BINUTILS_SRC"
clone "$GCC_GIT_URL"      "$GCC_GIT_REF"      "$GCC_SRC"

# GCC prerequisites (GMP/MPFR/MPC/ISL) — downloaded and built in-tree, so we
# don't depend on system copies.
if [ ! -e "$GCC_SRC/gmp" ]; then
    log "Downloading GCC prerequisites (gmp/mpfr/mpc/isl)"
    ( cd "$GCC_SRC" && ./contrib/download_prerequisites )
fi

# --------------------------------------------------------------------------
# 2. Build binutils
# --------------------------------------------------------------------------
export PATH="$PREFIX/bin:$PATH"

BINUTILS_BUILD="$BUILD_DIR/binutils"
if [ ! -f "$PREFIX/bin/${TARGET}-ld" ]; then
    log "Configuring binutils for $TARGET"
    rm -rf "$BINUTILS_BUILD"; mkdir -p "$BINUTILS_BUILD"
    sysroot_arg=()
    [ -n "$SYSROOT" ] && sysroot_arg=(--with-sysroot="$SYSROOT")
    ( cd "$BINUTILS_BUILD" && "$BINUTILS_SRC/configure" \
        --prefix="$PREFIX" \
        --target="$TARGET" \
        --disable-gold \
        --disable-gdb \
        --disable-gdbserver \
        --disable-sim \
        --disable-multilib \
        --disable-nls \
        --disable-werror \
        --enable-plugins \
        --with-arch=powerpc \
        "${sysroot_arg[@]}" )
    log "Building binutils"
    make -C "$BINUTILS_BUILD" -j"$JOBS"
    make -C "$BINUTILS_BUILD" install
else
    log "binutils already installed, skipping"
fi

# NOTE: no ar/ranlib wrapper. binutils' ar (2.46+) already defaults to the AIX
# big-archive (<bigaf>) format for AIX targets — verified, regular libgcc.a and
# the shared libgcc archives all come out as <bigaf>. Older binutils (2.43)
# wrote GNU "!<arch>" and needed a wrapper appending --target=aix5coff64-rs6000;
# that, plus its `ar` SIGSEGV on the shared object, is obsolete here.

# --------------------------------------------------------------------------
# 3. Build GCC (compiler only — 'all-gcc')
# --------------------------------------------------------------------------
GCC_BUILD="$BUILD_DIR/gcc"
gcc_configure() {
    local extra=("$@")
    rm -rf "$GCC_BUILD"; mkdir -p "$GCC_BUILD"
    ( cd "$GCC_BUILD" && "$GCC_SRC/configure" \
        --prefix="$PREFIX" \
        --target="$TARGET" \
        --enable-languages=c,c++ \
        --disable-nls \
        --disable-libssp \
        --with-cpu=powerpc64 \
        --disable-multilib \
        --with-aix-soname=svr4 \
        --disable-libgomp \
        --disable-libitm \
        --disable-libvtv \
        --disable-libsanitizer \
        --disable-libquadmath \
        "${extra[@]}" )
}
# This is a SINGLE-ARCH, 64-bit-only, SHARED C++ toolchain. The supported AIX
# model (per GCC bug 85907, D. Edelsohn) is shared libstdc++/libgcc — AIX links
# against the shared object even for "static", so a GNU-style static .a-of-.o
# libstdc++ produces multiple EH/init tables and crashes at static teardown.
# Hence we build SHARED, not --disable-shared. The config reasoning:
#
#  * binutils ar CANNOT build AIX "fat" archives (a 32-bit and a 64-bit member
#    of the same name); it keeps only the last. AIX libgcc's multilib model
#    combines both bitnesses into one fat libgcc.a, so a multilib build always
#    yields a corrupted, single-arch-wrong default libgcc -> link failures.
#    => --disable-multilib, and our GCC fork drops the fat-combine and just
#       install the normally-built single-arch libraries.
#
#  * --with-cpu=powerpc64 sets cpu_is_64bit -> biarch64/t-aix64 -> the compiler
#    defaults to 64-bit codegen. With multilib disabled there is exactly one
#    (64-bit) library set, so the default is internally consistent.
#
#  * --with-aix-soname=svr4 (runtime linking, -G/-brtl) is REQUIRED, not the
#    AIX default "aix"/"both" (-bnortl, traditional). The traditional model
#    statically resolves against this AIX libc, whose moveeq_64.o branches
#    ABSOLUTE to .___memmove64 — a symbol that exists ONLY in the shared libc
#    (no static archive member defines it), so -bnortl fails with "undefined
#    .___memmove64". svr4's runtime linking imports it at load time instead.
#    Deployment: libgcc_s.so.1 / libstdc++.so.6 must be present on the AIX
#    target at runtime (they are inside libgcc_s.a / libstdc++.a).
#
#  * libgomp/libitm/libvtv/libsanitizer/libquadmath disabled (not needed for a
#    C/C++ toolchain; each would need its own single-arch t-aix patch).
#    libatomic IS kept + patched (out-of-line atomic fallback).
#
# AIX/PowerPC is big-endian only, so no endianness flag is needed.

if [ -z "$SYSROOT" ]; then
    warn "No --sysroot given."
    warn "Building binutils + the bare compiler (all-gcc) only."
    warn "libgcc and a usable toolchain need AIX headers/libs; supply --sysroot to finish."
    log "Configuring GCC (no sysroot, headers-less compiler stage)"
    gcc_configure --without-headers --with-newlib --disable-shared --disable-threads
    log "Building all-gcc"
    make -C "$GCC_BUILD" -j"$JOBS" all-gcc
    make -C "$GCC_BUILD" install-gcc
    cat <<EOF

------------------------------------------------------------------------
Partial toolchain built (no sysroot).

Installed:
  $PREFIX/bin/${TARGET}-as, -ld, ...   (binutils)
  $PREFIX/bin/${TARGET}-gcc            (compiler driver + cc1, no libgcc)

This compiler can parse/emit AIX assembly but CANNOT link a working
program: it has no AIX C library, crt files, or libgcc.

To finish, obtain an AIX sysroot and re-run:
  $0 --sysroot /path/to/aix-sysroot

See the "Harvesting an AIX sysroot" notes at the bottom of this script.
------------------------------------------------------------------------
EOF
    exit 0
fi

# --- Full build with sysroot ---------------------------------------------
[ -d "$SYSROOT" ] || die "Sysroot path does not exist: $SYSROOT"
# Sanity-check the sysroot looks like AIX. Use -e (follows symlinks) so a
# dangling link counts as missing — AIX headers/libs are heavily symlinked.
if [ ! -e "$SYSROOT/usr/include/stdio.h" ]; then
    warn "Sysroot $SYSROOT has no usable usr/include/stdio.h — is this a real AIX sysroot?"
fi
if [ ! -e "$SYSROOT/usr/lib/libc.a" ]; then
    warn "usr/lib/libc.a does not resolve in $SYSROOT (likely a dangling symlink)."
    if [ -L "$SYSROOT/usr/lib/libc.a" ]; then
        warn "  it points to: $(readlink "$SYSROOT/usr/lib/libc.a")"
    fi
    warn "  On AIX the real archive lives in /usr/ccs/lib — make sure you harvested"
    warn "  /usr/ccs/lib into the sysroot (see notes at the bottom of this script)."
    warn "  Linking (libgcc_s) will fail with 'library libc not found' otherwise."
fi

log "Configuring GCC for $TARGET with sysroot $SYSROOT"
gcc_configure --with-sysroot="$SYSROOT"

log "Building all-gcc"
make -C "$GCC_BUILD" -j"$JOBS" all-gcc
make -C "$GCC_BUILD" install-gcc

# Post-process the svr4 shared libgcc archive in DIR (must contain
# libgcc_s.so.1), fixing three things that otherwise break a Linux-hosted cross
# link against this AIX shared libgcc:
#   1. member order — the t-slibgcc-aix rule archives "shr.imp shr.o" (text
#      import file first), but GCC's collect2 (collect2-aix.cc) only inspects
#      the FIRST member and needs a real XCOFF object there, else ldopen fails
#      -> "cannot open as COFF file". Put shr.o first.
#   2. bit-width marker — for a single-arch 64-bit build multilib_dir is ".", so
#      the rule's `case ... in *64*)` misses and writes "# 32" into the import
#      file though shr.o is 64-bit XCOFF. Correct it to "# 64".
#   3. missing archive — svr4 emits only libgcc_s.so.1 (+ .so symlink), but AIX
#      `ld -lgcc_s` searches for libgcc_s.a. Provide it as the same corrected
#      archive; its import file's `#!` line points the loader at libgcc_s.so.1.
fix_libgcc_s() {
    local dir="$1" ar="$PREFIX/bin/${TARGET}-ar" so="$1/libgcc_s.so.1" tmp
    [ -f "$so" ] || { warn "fix_libgcc_s: no $so"; return 0; }
    tmp="$(mktemp -d)"
    cp "$so" "$tmp/in.a"
    ( cd "$tmp" && "$ar" -X32_64 x in.a )
    if [ -f "$tmp/shr.imp" ] && [ -f "$tmp/shr.o" ]; then
        sed -i 's/^# 32$/# 64/' "$tmp/shr.imp"
        ( cd "$tmp" && rm -f out.a && "$ar" -X32_64 rc out.a shr.o shr.imp )
        cp "$tmp/out.a" "$so"
        cp "$tmp/out.a" "$dir/libgcc_s.a"
        rm -f "$dir/libgcc_s.so"; ( cd "$dir" && ln -s libgcc_s.so.1 libgcc_s.so )
        log "fix_libgcc_s: corrected $so (+ libgcc_s.a) in $dir"
    else
        warn "fix_libgcc_s: unexpected members in $so; left as-is"
    fi
    rm -rf "$tmp"
}

log "Building target libgcc"
make -C "$GCC_BUILD" -j"$JOBS" all-target-libgcc
# Correct the shared libgcc in the build tree so the libstdc++/libatomic links
# (which pull -lgcc_s from $GCC_BUILD/gcc) succeed.
fix_libgcc_s "$GCC_BUILD/gcc"
make -C "$GCC_BUILD" install-target-libgcc

log "Building the rest of GCC (libstdc++, etc.)"
make -C "$GCC_BUILD" -j"$JOBS"
make -C "$GCC_BUILD" install
# Correct the shared libgcc in the INSTALLED tree too (install copies the raw,
# import-first .so.1 and omits libgcc_s.a).
fix_libgcc_s "$PREFIX/$TARGET/lib"

cat <<EOF

------------------------------------------------------------------------
Done. Cross-compiler installed at:
  $PREFIX/bin/${TARGET}-gcc

Quick test (C):
  echo 'int main(void){return 0;}' > /tmp/t.c
  $PREFIX/bin/${TARGET}-gcc --sysroot="$SYSROOT" -o /tmp/t /tmp/t.c
  file /tmp/t        # should report an AIX/XCOFF executable

C++ shared library (the supported AIX model):
  $PREFIX/bin/${TARGET}-g++ --sysroot="$SYSROOT" -shared -Wl,-brtl -o libfoo.so foo.cpp
  # At RUNTIME on AIX, the shared C++ runtime must be reachable via LIBPATH:
  #   $PREFIX/$TARGET/lib/{libstdc++.a,libgcc_s.a,libgcc_s.so.1,libatomic.a}
  # (libstdc++.so.6 lives inside libstdc++.a as the AIX shared-archive member).

Add to PATH:
  export PATH="$PREFIX/bin:\$PATH"
------------------------------------------------------------------------
EOF

# ==========================================================================
# Harvesting an AIX sysroot (cannot be downloaded — proprietary)
# ==========================================================================
#
# On a licensed AIX system of the version you target, as root.
# Note: AIX's stock /usr/bin/tar is classic tar (no -z), so pipe through
# gzip. The sysroot is mostly text headers and .a archives, which compress
# well, so this keeps the file you copy back small.
#
#   mkdir -p /tmp/aix-sysroot/usr/ccs
#   cp -hpR /usr/include   /tmp/aix-sysroot/usr/
#   cp -hpR /usr/lib       /tmp/aix-sysroot/usr/
#   cp -hpR /usr/ccs/lib   /tmp/aix-sysroot/usr/ccs/   # REAL archives live here
#   cp -hpR /lib           /tmp/aix-sysroot/      2>/dev/null || true
#   ( cd /tmp && tar -cf - aix-sysroot | gzip -c > aix-sysroot.tar.gz )
#
# IMPORTANT: /usr/ccs/lib is essential. On AIX the real archives (libc.a,
# libpthreads.a, libm.a, libdl.a, ...) live in /usr/ccs/lib, and /usr/lib/*.a
# are mostly symlinks pointing into it. Harvest /usr/lib alone and the linker
# fails with "library libc not found". The symlink-normalization step in this
# script then rewires /usr/lib/libc.a -> /usr/ccs/lib/libc.a inside the sysroot.
#
# Copy aix-sysroot.tar.gz to this Linux host and pass it straight to
# --sysroot — this script extracts it and finds the root for you:
#
#   ./build-aix-cross.sh --sysroot /path/to/aix-sysroot.tar.gz
#
# The key contents the toolchain needs:
#   usr/include/*          AIX system headers
#   usr/lib/libc.a         AIX C library (archive of shared objects)
#   usr/lib/crt0*.o, etc.  C runtime startup objects
#   usr/lib/libpthreads.a, libm.a, ...
#
# Note: AIX .a libraries are archives that contain shared objects (.so
# members), which is why binutils must be built with XCOFF support (the
# default for the powerpc-ibm-aix target; gold is disabled because it is
# ELF-only).
