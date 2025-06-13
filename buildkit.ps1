# Source: https://github.com/moby/buildkit/blob/master/docs/windows.md#setup-instructions
. .\windows\helpers.ps1
$version = "v0.22.0"
$arch = "amd64" # arm64 binary available too
$sha256 = "e76584227535814b25be9bb202ef400fd43c32b74c3ed3a0a05e9ceee40b3f66"
$buildkit_url = "https://github.com/moby/buildkit/releases/download/$version/buildkit-$version.windows-$arch.tar.gz"
$out = "$($PSScriptRoot)\buildkit-$version.windows-$arch.tar.gz"
Get-RemoteFile -RemoteFile $buildkit_url -LocalFile $out -VerifyHash $sha256
# there could be another `.\bin` directory from containerd instructions
# you can move those
mv bin bin2
tar.exe xvf .\buildkit-$version.windows-$arch.tar.gz
## x bin/
## x bin/buildctl.exe
## x bin/buildkitd.exe
# after the binaries are extracted in the bin directory
# move them to an appropriate path in your $Env:PATH directories or:
Copy-Item -Path ".\bin" -Destination "$Env:ProgramFiles\buildkit" -Recurse -Force
# add `buildkitd.exe` and `buildctl.exe` binaries in the $Env:PATH
$Path = [Environment]::GetEnvironmentVariable("PATH", "Machine") + `
    [IO.Path]::PathSeparator + "$Env:ProgramFiles\buildkit"
[Environment]::SetEnvironmentVariable( "Path", $Path, "Machine")
$Env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + `
    [System.Environment]::GetEnvironmentVariable("Path","User")
