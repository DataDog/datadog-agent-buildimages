#
# Installs embedded python2 and python3 for use in unit testing.
# Be careful to use unique environment variables indicating location
# of the python files.
#
# We need to provide a location so that the test scripts can find python,
# but also need to make sure it doesn't confuse the actual builds.
#

# Uses:
# EMBEDDED_PYTHON_2_VERSION
# EMBEDDED_PYTHON_3_VERSION

# this downloads the necessary file

$ErrorActionPreference = 'Stop'

$py2 = "https://s3.amazonaws.com/dd-agent-omnibus/python-windows-${Env:EMBEDDED_PYTHON_2_VERSION}-amd64.zip"
$py3 = "https://s3.amazonaws.com/dd-agent-omnibus/python-windows-${Env:EMBEDDED_PYTHON_3_VERSION}-amd64.zip"

$py2Target = "c:\embeddedpy\py${Env:EMBEDDED_PYTHON_2_VERSION}"
$py3Target = "c:\embeddedpy\py${Env:EMBEDDED_PYTHON_3_VERSION}"

DownloadAndExpandTo -TargetDir $py2Target -SourceURL $py2 -Sha256 "$Env:EMBEDDED_PYTHON_2_SHA256"

DownloadAndExpandTo -TargetDir $py3Target -SourceURL $py3 -Sha256 "$Env:EMBEDDED_PYTHON_3_SHA256"

Add-EnvironmentVariable -Variable "TEST_EMBEDDED_PY2" -Value $py2Target -Global
Add-EnvironmentVariable -Variable "TEST_EMBEDDED_PY3" -Value $py3Target -Global

# Read DD_PIP_VERSION{,_PY3} and DD_SETUPTOOLS_VERSION{,_PY3} to variables
Get-Content \python-packages-versions.txt | Where-Object { $_.Trim() -ne '' } | Where-Object { $_.Trim() -notlike "#*" } | Foreach-Object{
   $var = $_.Split('=')
   Add-EnvironmentVariable -Variable $var[0] -Value $var[1] -Local
}

# Python 2
$py2getpip = "https://raw.githubusercontent.com/pypa/get-pip/38e54e5de07c66e875c11a1ebbdb938854625dd8/public/2.7/get-pip.py"
$py2getpipsha256 = "40ee07eac6674b8d60fce2bbabc148cf0e2f1408c167683f110fd608b8d6f416"
Get-RemoteFile -LocalFile "get-pip.py" -RemoteFile $py2getpip -VerifyHash $py2getpipsha256
& "$py2Target\python" get-pip.py pip==${Env:DD_PIP_VERSION}
If ($lastExitCode -ne "0") { throw "Previous command returned $lastExitCode" }
& "$py2Target\python" -m pip install -r ../requirements-py2.txt
If ($lastExitCode -ne "0") { throw "Previous command returned $lastExitCode" }

# Python 3
$py3getpip = "https://raw.githubusercontent.com/pypa/get-pip/38e54e5de07c66e875c11a1ebbdb938854625dd8/public/get-pip.py"
$py3getpipsha256 = "e235c437e5c7d7524fbce3880ca39b917a73dc565e0c813465b7a7a329bb279a"
Get-RemoteFile -LocalFile "get-pip.py" -RemoteFile $py3getpip -VerifyHash $py3getpipsha256
& "$py3Target\python" get-pip.py pip==${Env:DD_PIP_VERSION_PY3}
If ($lastExitCode -ne "0") { throw "Previous command returned $lastExitCode" }
& "$py3Target\python" -m pip install -r ../requirements.txt
If ($lastExitCode -ne "0") { throw "Previous command returned $lastExitCode" }
