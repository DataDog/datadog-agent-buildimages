$ErrorActionPreference = "Stop"

# Do not use '--depth 1' since vcpkg needs to browse its git history for dependency retrieval
git clone --branch 2021.05.12 https://github.com/microsoft/vcpkg

git clone https://github.com/microsoft/vcpkg-tool --branch 2022-01-19 C:\vcpkg-tool

mkdir C:\vcpkg-build
Push-Location C:\vcpkg-build
cmake -DVCPKG_EMBED_GIT_SHA=ON C:\vcpkg-tool
cmd /C "%VSTUDIO_ROOT%\VC\Auxiliary\Build\vcvars64.bat && msbuild /p:Configuration=Release vcpkg.sln"
Move-Item C:\vcpkg-build\Release\vcpkg.exe c:\vcpkg\
Pop-Location

Remove-Item -Recurse -Force C:\vcpkg-tool
Remove-Item -Recurse -Force C:\vcpkg-build

[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\vcpkg\", [System.EnvironmentVariableTarget]::Machine)
.\vcpkg\vcpkg.exe --version
.\vcpkg\vcpkg.exe integrate install
