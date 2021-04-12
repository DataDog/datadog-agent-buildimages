git clone --depth 1 https://github.com/microsoft/vcpkg
.\vcpkg\scripts\bootstrap.ps1
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\vcpkg\", [System.EnvironmentVariableTarget]::Machine)
.\vcpkg\vcpkg.exe integrate install
