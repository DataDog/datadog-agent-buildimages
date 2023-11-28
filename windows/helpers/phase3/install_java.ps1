$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host -ForegroundColor Green "Installing Java $ENV:JAVA_VERSION"

## java now downloaded from microsoft site.  Has much more predictable download path
## https://aka.ms/download-jdk/microsoft-jdk-17.0.8-windows-x64.zip
$javazip = "https://aka.ms/download-jdk/microsoft-jdk-$($ENV:JAVA_VERSION)-windows-x64.zip"

$out = "$($PSScriptRoot)\java.zip"

Write-Host -ForegroundColor Green "Downloading $javazip to $out"

(New-Object System.Net.WebClient).DownloadFile($javazip, $out)
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$ENV:JAVA_SHA256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$ENV:JAVA_SHA256'.\"; exit 1 }

mkdir c:\tmp\java

Write-Host -ForegroundColor Green "Extracting $out to c:\tmp\java"

Start-Process "7z" -ArgumentList "x -oc:\tmp\java $out" -Wait

Write-Host -ForegroundColor Green "Removing temporary file $out"

Remove-Item $out

Add-EnvironmentVariable -Variable JAVA_HOME -Value "c:\openjdk-17" -Global -Local

## move expanded file from tmp dir to final resting place
## note must be after env variable set above.

Move-Item -Path c:\tmp\java\* -Destination $Env:JAVA_HOME

Add-ToPath -NewPath "$($Env:JAVA_HOME)\bin" -Local -Global

Write-Host -ForegroundColor Green "Installed java $ENV:JAVA_VERSION"
Write-Host -ForegroundColor Green 'javac --version'; javac --version
Write-Host -ForegroundColor Green 'java --version'; java --version

## need to have more rigorous download at some point, but
$jsignfile = "jsign-$($ENV:JSIGN_VERSION).jar"
$jsignjarsrc = "https://github.com/ebourg/jsign/releases/download/$($ENV:JSIGN_VERSION)/$($jsignfile)"
$jsignjardir = "c:\devtools\jsign"
$jsignout = "$($jsignjardir)\$($jsignfile)"
if (-Not (test-path $jsignjardir)) {
    mkdir $jsignjardir
}
(New-Object System.Net.WebClient).DownloadFile($jsignjarsrc, $jsignout)

Add-EnvironmentVariable -Variable JARSIGN_JAR -Value $jsignout -Global
