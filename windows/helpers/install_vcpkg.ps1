$ErrorActionPreference = "Stop"
$branch = "2022.03.10"

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "vcpkg" -Keyname "version" -TargetValue $branch
if($isInstalled -and $isCurrent){
    Write-Host -ForegroundColor Green "VCPkg up to date"
    return
}
if(-not $isCurrent) {
    Remove-Item -recurse -force c:\vcpkg -ErrorAction SilentlyContinue
    Write-Host -ForegroundColor Green "Upgrading VCPkg"
}
# Do not use '--depth 1' since vcpkg needs to browse its git history for dependency retrieval
git clone --branch $branch https://github.com/microsoft/vcpkg c:\vcpkg

git clone https://github.com/microsoft/vcpkg-tool --branch 2022-03-30 C:\vcpkg-tool

mkdir C:\vcpkg-build
Push-Location C:\vcpkg-build
cmake -DVCPKG_EMBED_GIT_SHA=ON -DVCPKG_BASE_VERSION=2022-03-30 C:\vcpkg-tool
Get-Command cmd -all
cmd /C "%VSTUDIO_ROOT%\VC\Auxiliary\Build\vcvars64.bat && msbuild /p:Configuration=Release vcpkg.sln"

Move-Item C:\vcpkg-build\Release\vcpkg.exe c:\vcpkg\
Pop-Location

Remove-Item -Recurse -Force C:\vcpkg-tool
Remove-Item -Recurse -Force C:\vcpkg-build

Add-ToPath -NewPath "C:\vcpkg" -Global
c:\vcpkg\vcpkg.exe --version
c:\vcpkg\vcpkg.exe integrate install
Set-InstalledVersionKey -Component "vcpkg" -Keyname "version" -TargetValue $branch