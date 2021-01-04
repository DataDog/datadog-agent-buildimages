::
:: Installs .NET Runtime 3.5, used by Wix 3.11 and the Visual C++ Compiler for Python 2.7
:: Taken from the mcr.microsoft.com/dotnet/framework/runtime:3.5 Dockerfile:
;; https://github.com/microsoft/dotnet-framework-docker/blob/e0b59f4aeb47bd6bf13e4c7ec6676a1935306df9/src/runtime/3.5/windowsservercore-20H2/Dockerfile
::

set DOTNET_RUNNING_IN_CONTAINER true

curl -fSLo microsoft-windows-netfx3.zip https://dotnetbinaries.blob.core.windows.net/dockerassets/microsoft-windows-netfx3-2009.zip
tar -zxf microsoft-windows-netfx3.zip
del /F /Q microsoft-windows-netfx3.zip
DISM /Online /Quiet /Add-Package /PackagePath:.\microsoft-windows-netfx3-ondemand-package~31bf3856ad364e35~amd64~~.cab
del microsoft-windows-netfx3-ondemand-package~31bf3856ad364e35~amd64~~.cab
powershell Remove-Item -Force -Recurse ${Env:TEMP}\*

curl -fSLo patch.msu http://download.windowsupdate.com/c/msdownload/update/software/updt/2020/10/windows10.0-kb4580419-x64-ndp48_197efbd77177abe76a587359cea77bda5398c594.msu
mkdir patch
expand patch.msu patch -F:*
del /F /Q patch.msu
DISM /Online /Quiet /Add-Package /PackagePath:C:\patch\Windows10.0-KB4580419-x64-NDP48.cab
rmdir /S /Q patch