$SoftwareTable = @{
    "GIT_VERSION"="2.26.2";
    "GIT_SHA256"="2dfbb1c46547c70179442a92b8593d592292b8bce2fd02ac4e0051a8072dde8f";
    "WINGIT_URL"="https://github.com/git-for-windows/git/releases/download/v2.37.3.windows.1/Git-2.37.3-64-bit.exe";
    "WINGIT_SHA256"="b0442f1b8ea40b6f94ef9a611121d2c204f6aa7f29c54315d2ce59876c3d134e";
    "SEVENZIP_VERSION"="19.0.0";
    "SEVENZIP_SHA256"="0f5d4dbbe5e55b7aa31b91e5925ed901fdf46a367491d81381846f05ad54c45e";
    "SEVENZIP_STANDALONE_VERSION"="24.08";
    "SEVENZIP_STANDALONE_SHA256"="1B16C41AE39B679384B06F1492B587B650716430FF9C2E079DCA2AD1F62C952D";

    ## VisualStudio build tools for containers
    # https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-history
    # LTSC 17.8
    "VS2017BUILDTOOLS_VERSION"="17.8.7";
    "VS2017BUILDTOOLS_DOWNLOAD_URL"="https://download.visualstudio.microsoft.com/download/pr/03aef663-a3da-4cdd-ac33-9ff2935267ba/fc12f5b47ac9ec42064cfad9e40efe3b88ef5468e82bafec7839ef3296fd88a3/vs_BuildTools.exe";

    # Get-FileHash -Algorithm SHA256 -InputStream ([System.Net.WebClient]::new().OpenRead('https://download.visualstudio.microsoft.com/download/pr/03aef663-a3da-4cdd-ac33-9ff2935267ba/fc12f5b47ac9ec42064cfad9e40efe3b88ef5468e82bafec7839ef3296fd88a3/vs_BuildTools.exe'))
    "VS2017BUILDTOOLS_SHA256"="FC12F5B47AC9EC42064CFAD9E40EFE3B88EF5468E82BAFEC7839EF3296FD88A3";

    ## VisualStudio IDE
    # https://learn.microsoft.com/en-us/visualstudio/releases/2019/history
    "VS2019INSTALLER_DOWNLOAD_URL"="https://download.visualstudio.microsoft.com/download/pr/3a7354bc-d2e4-430f-92d0-9abd031b5ee5/d9fc228ea71a98adc7bc5f5d8e8800684c647e955601ed721fcb29f74ace7536/vs_Community.exe";
    "VS2019INSTALLER_SHA256"="d9fc228ea71a98adc7bc5f5d8e8800684c647e955601ed721fcb29f74ace7536";

    "DOTNETCORE_VERSION"="8.0.302";
    "DOTNETCORE_SHA256"="BC6019E0192EDD180CA7B299A16B95327941B0B53806CDB125BE194AEA12492D";
    "DOTNETCORE_URL"="https://download.visualstudio.microsoft.com/download/pr/b6f19ef3-52ca-40b1-b78b-0712d3c8bf4d/426bd0d376479d551ce4d5ac0ecf63a5/dotnet-sdk-8.0.302-win-x64.exe";

    "RUBY_VERSION"="2.6.6-1";
    "RUBY_SHA256"="fbdf77a3e1fa36e25cf0af1303ac76f67dec7a6f739a829784a299702cad1492";
    "PYTHON_VERSION"="3.12.6";
    "PYTHON_SHA256"="5914748e6580e70bedeb7c537a0832b3071de9e09a2e4e7e3d28060616045e0a";
    "WIX_VERSION"="3.11.2";
    "WIX_SHA256"="32bb76c478fcb356671d4aaf006ad81ca93eea32c22a9401b168fc7471feccd2";
    "CMAKE_VERSION"="3.30.2";
    "CMAKE_SHA256"="31f799a9e7756305f74cd821970a793e599ead230925392886f45aed897a3c0e";
    "MSYS_VERSION"="20241208";
    "MSYS_SHA256"="DFAED9EE4E1A28C24ED06EDBB0767846A1022EB3EC849D70B2B999129E472135";
    "NUGET_VERSION"="5.8.0";
    "NUGET_SHA256"="5c5b9c96165d3283b2cb9e5b65825d343e0e7139b9e70a250b4bb24c2285f3ba";
    "WINGET_VERSION"="1.6.5.0";
    "WINGET_SHA256"="2CCED75B1830246A78FF0E57F18133807F78BA484CCA2D369CBDDF490DDAC1AF";
    "EMBEDDED_PYTHON_3_VERSION"="3.12.6";
    "EMBEDDED_PYTHON_3_SHA256"="045d20a659fe80041b6fd508b77f250b03330347d64f128b392b88e68897f5a0";
    "EMBEDDED_PIP_VERSION"="20.3.4";
    "CODEQL_VERSION"="2.10.3";
    "CODEQL_HASH"="46f64e21c74f41210ea3f2c433d1dc622e3eb0690b42373a73fba82122b929a1";
    "VAULT_VERSION"="1.17.2";
    "VAULT_HASH"="7ed488aa8bbae5da75cbb909d454c5e86d7ac18389bdd9f844ce58007c6e3ac3";
    "NINJA_VERSION"="1.11.0";
    "NINJA_SHA256"="d0ee3da143211aa447e750085876c9b9d7bcdd637ab5b2c5b41349c617f22f3b";
    "GCLOUD_SDK_VERSION"="315.0.0";
    "GCLOUD_SDK_SHA256"="c9b283c9db4ed472111ccf32e6689fd467daf18ce3a77b8e601f9c646a83d86b";
    "CACERTS_VERSION"="2024-12-31";
    "CACERTS_HASH"="a3f328c21e39ddd1f2be1cea43ac0dec819eaa20a90425d7da901a11531b3aa5";
    "JAVA_VERSION"="17.0.8";
    "JAVA_SHA256"="db6e7e7506296b8a2338f6047fdc94bf4bbc147b7a3574d9a035c3271ae1a92b";
    "JSIGN_VERSION"="5.0";
    "WINSIGN_VERSION"="0.3.0";
    "WINSIGN_SHA256"="43c1429e1e23fba2f9284da2d12027b5be58258c6b047c65ff8e2d46370072ba";
    "RUSTUP_VERSION"="1.26.0";
    "RUSTUP_SHA256"="365D072AC4EF47F8774F4D2094108035E2291A0073702DB25FA7797A30861FC9";
    "RUST_VERSION"="1.74.0";
    "CI_UPLOADER_VERSION"="2.38.1";
    "CI_UPLOADER_SHA256"="b8311e01cbe71ead8d64ff123eddde1d3df31b80a4bed200d17a41b88e873ed5";
    "CODECOV_VERSION"="v0.6.1";
    "CODECOV_SHA256"="6b95584fbb252b721b73ddfe970d715628879543d119f1d2ed08b073155f7d06";
}
