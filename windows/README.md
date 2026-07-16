# Building on Windows

This part of the repo contains the Dockerfile of the image used to build Windows
container which will be used to build Datadog Agent for Windows.

## [Experimental] Converting Dockerfile to Powershell script

Run [dockerfile-to-powershell.py](dockerfile-to-powershell.py) script to convert Windows
Dockerfile instructions to the logically equivalent Powershell script which will make
clean Windows machine ready for building Agent for Windows platform (without Docker
involvement).

Example of the generated Powershell file is added to the repo as [dockerfile-to-powershell-generated-sample.ps1](dockerfile-to-powershell-generated-sample.ps1)
but it will be outdated next time the Dockerfile is changed (in the future we may
automatically regenerate it).

### Phase 1: Generate Powershell script

You need only the script itself and the Dockerfile (and [requirements.txt](requirements.txt) - to run `pip install -r requirements.txt`).

**Example**
```
  .\dockerfile-to-powershell.py 
       -d .\Dockerfile 
       -p .\dockerfile-to-powershell-generated-sample.ps1
       -a WINDOWS_VERSION=2022
       -a DD_TARGET_ARCH=x64 
```

### Phase 2: Create Windows Build Machine

Prerequisites

- [.NET 4.8 installation](https://support.microsoft.com/en-us/topic/microsoft-net-framework-4-8-offline-installer-for-windows-9d23f658-3b97-68ab-d013-aa3c3e7495e0)
- Local clone of this repo

**Example**
```
cd C:\
Powershell
.\dockerfile-to-powershell-generated-sample.ps1 -DockerRepoPath C:\datadog-agent-buildimages
```

*Note*: On the moderately beefy VM this Powershell script may take 30-40 minutes to complete.

### Phase 3 (Optional): Build Agent

Now we are ready to build Agent. We can run exactly the same commands as with the Docker-based Windows build

**Example**
```
git clone https://github.com/DataDog/datadog-agent.git C:\mnt
set OMNIBUS_TARGET=main&set RELEASE_VERSION=nightly&set MAJOR_VERSION=7&set PY_RUNTIMES=3&set TARGET_ARCH=x64&c:\mnt\tasks\winbuildscripts\buildwin.bat
```
Caveats:
* C:\mnt will be checked by the script and is required directory containing Agent sources
* Environment variables command line should not have spaces around "&"
* We have seen cases when "ridk enable" commands had to run
