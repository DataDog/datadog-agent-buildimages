REM
REM This is a tweak for the in-house CPython build which requests a weird compiler version.
REM The registry keys will redirect the nonexisting v13.2 compiler to the local VS 2019 toolchain.
REM
reg add "HKEY_CURRENT_USER\Software\Microsoft\DevDiv\VCForPython\13.2" /v InstallDir     /t REG_SZ    /d C:\devtools\vstudio\VC\Auxiliary\Build\ /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\DevDiv\VCForPython\13.2" /v StartMenuItems /t REG_DWORD /d 1                                       /f
