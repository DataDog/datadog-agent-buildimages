# AIX cross-compiler

`build-aix-cross.sh` builds a Linux-hosted GCC + binutils toolchain targeting
`powerpc-ibm-aix`. crosstool-ng doesn't support AIX, hence the dedicated script.

Versions and sources are pinned in `aix-version.env`. Changing any of the AIX
build inputs changes the toolchain hash, so CI rebuilds and publishes a new
artifact to MASS.

## Forks

Upstream GCC and binutils need fixes to build working AIX binaries. Those
fixes live in forks, in branches that are also used to upstream them:

- GCC: https://github.com/chouquette/gcc
  - `chouquette/datadog-patchset-gcc-13`: on top of GCC 13, matching the
    libstdc++ shipped by IBM's AIX Toolbox. This is what we build.
  - `chouquette/datadog-patchset-last-stable`: on top of the latest release.
  - `chouquette/datadog-patchset`: on top of upstream `master`.
- binutils: https://github.com/chouquette/binutils-gdb
  - `chouquette/datadog-patchset-last-stable`: on top of the latest release.
    This is what we build.
  - `chouquette/datadog-patchset`: on top of upstream `master`.

The build uses tags cut from those branches, named
`datadog-aix-<gcc|binutils>-<upstream version>-<revision>`.

## Updating

1. Rebase the relevant fork branch on the new upstream baseline and fix
   conflicts.
2. Push a new tag, bumping the revision for patch-only changes.
3. Update the matching `*_GIT_REF` in `aix-version.env`.

## Sysroot

The AIX headers and libraries are proprietary and can't be downloaded. The
sysroot is stored on MASS (`AIX_SYSROOT_URL`), and the resulting toolchain
archive embeds it, so it's only published to MASS, never to the public
bucket. See the end of `build-aix-cross.sh` for how to harvest a new sysroot
from an AIX machine.
