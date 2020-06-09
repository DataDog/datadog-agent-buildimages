$ErrorActionPreference = 'Stop'

function Code-Check {
    param ($Code, $Element)
    if ($Code -ne 0) {
        Write-Host -ForegroundColor Red "$Element install failed"
        [Environment]::Exit(1)
    }
}

# git, ridk and bundler aren't available yet right after they're installed, you need to restart a shell

### HACK: we disable symbolic links when cloning repositories
### to work around a symlink-related failure in the agent-binaries omnibus project
### when copying the datadog-agent project twice.
git config --system core.symlinks false

# Install 64-bit C/C++ compilation toolchain
ridk install 3
Code-Check -Code $LASTEXITCODE -Element "ridk"


setx RIDK ((Get-Command ridk).Path)

# (32-bit only) Install 32-bit C/C++ compilation toolchain
if ($Env:TARGET_ARCH -eq 'x86') { ridk enable; bash -c "pacman -S --needed --noconfirm mingw-w64-i686-binutils mingw-w64-i686-crt-git mingw-w64-i686-gcc mingw-w64-i686-gcc-libs mingw-w64-i686-headers-git mingw-w64-i686-libmangle-git mingw-w64-i686-libwinpthread-git mingw-w64-i686-make mingw-w64-i686-pkg-config mingw-w64-i686-tools-git mingw-w64-i686-winpthreads-git" }
Code-Check -Code $LASTEXITCODE -Element "32-bit ridk"


if ($Env:TARGET_ARCH -eq 'x86') { [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\tools\msys64\mingw32\bin;C:\tools\msys64\usr\bin", [System.EnvironmentVariableTarget]::Machine) }

# Install bundler for omnibus builds
gem install bundler
Code-Check -Code $LASTEXITCODE -Element "bundler"
