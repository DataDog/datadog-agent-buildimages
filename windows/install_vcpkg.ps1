$ErrorActionPreference = "Stop"

# Do not use '--depth 1' since vcpkg needs to browse its git history for dependency retrieval
git clone --branch 2021.05.12 https://github.com/microsoft/vcpkg

git clone https://github.com/microsoft/vcpkg-tool
Push-Location vcpkg-tool
cmake .
cmd /C "%VSTUDIO_ROOT%\VC\Auxiliary\Build\vcvars64.bat & msbuild /p:Configuration=Release vcpkg.sln"
Move-Item .\Release\vcpkg.exe c:\vcpkg\
Pop-Location
Remove-Item -Recurse -Force C:\vcpkg-tool

[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\vcpkg\", [System.EnvironmentVariableTarget]::Machine)
.\vcpkg\vcpkg.exe --version
.\vcpkg\vcpkg.exe integrate install
