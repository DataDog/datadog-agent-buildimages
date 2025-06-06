$url = "https://api.github.com/repos/moby/buildkit/releases/latest"
$version = (Invoke-RestMethod -Uri $url -UseBasicParsing).tag_name
$arch = "amd64" # arm64 binary available too
curl.exe -fSLO https://github.com/moby/buildkit/releases/download/$version/buildkit-$version.windows-$arch.tar.gz
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
buildkitd `
    --register-service `
    --service-name buildkitd `
    --containerd-cni-config-path="C:\Program Files\containerd\cni\conf\0-containerd-nat.conf" `
    --containerd-cni-binary-dir="C:\Program Files\containerd\cni\bin" `
    --debug `
    --log-file="C:\Windows\Temp\buildkitd.log"