$ErrorActionPreference = "Stop"

$buildVcpkgFromSource = $False
# See https://github.com/microsoft/vcpkg/releases for updated version
$vcpkgVersion = "2022.03.10"
# See https://github.com/microsoft/vcpkg-tool/releases for updated version
$vcpkgToolVersion = "2022-03-30"

# Do not use '--depth 1' since vcpkg needs to browse its git history for dependency retrieval
git clone --branch $vcpkgVersion https://github.com/microsoft/vcpkg

if ($buildVcpkgFromSource) {
    git clone https://github.com/microsoft/vcpkg-tool --branch $vcpkgToolVersion C:\vcpkg-tool
    mkdir C:\vcpkg-build
    Push-Location C:\vcpkg-build
    cmake -DVCPKG_EMBED_GIT_SHA=ON -DVCPKG_BASE_VERSION=$vcpkgToolVersion C:\vcpkg-tool
    cmd /C "%VSTUDIO_ROOT%\VC\Auxiliary\Build\vcvars64.bat && msbuild /p:Configuration=Release vcpkg.sln"
    Move-Item C:\vcpkg-build\Release\vcpkg.exe c:\vcpkg\
    Pop-Location
    Remove-Item -Recurse -Force C:\vcpkg-tool
    Remove-Item -Recurse -Force C:\vcpkg-build
} else {
    .\vcpkg\scripts\bootstrap.ps1
}

[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\vcpkg\", [System.EnvironmentVariableTarget]::Machine)
.\vcpkg\vcpkg.exe --version
.\vcpkg\vcpkg.exe integrate install
