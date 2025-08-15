# Install & verify Bazelisk (Go package) as Bazel bootstrapper

# set -euo pipefail
$ErrorActionPreference = 'Stop'

go install github.com/bazelbuild/bazelisk@v1.27.0

# ln -s bazelisk "$(command -v bazelisk | sed 's/bazelisk$/bazel/')"
Set-Location (Split-Path (Get-Command bazelisk).Source)
try {
    New-Item -ItemType SymbolicLink -Path bazel.exe -Target bazelisk.exe
} finally {
    Set-Location -
}

# bazelisk_home="$(mktemp -d)"
$bazeliskHome = New-Item -ItemType Directory -Path (Join-Path [System.IO.Path]::GetTempPath() [System.IO.Path]::GetRandomFileName())
try {
    # BAZELISK_HOME=$bazelisk_home USE_BAZEL_VERSION=7.6.1 bazel --version | grep -Fq 'bazel 7.6.1'
    $version = & {
        $env:BAZELISK_HOME = $bazeliskHome
        $env:USE_BAZEL_VERSION = '7.6.1'
        bazel --version
    }
    if ($version -ne 'bazel 7.6.1') {
        Write-Error "Unexpected bazel version: $version"
    }
} finally {
    # trap 'rm -rv -- "$bazelisk_home"' EXIT
    Remove-Item -Recurse -Verbose $bazeliskHome
}
