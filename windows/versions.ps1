$SoftwareTable = @{
    "GIT_VERSION"="2.26.2";
    "GIT_SHA256"="2dfbb1c46547c70179442a92b8593d592292b8bce2fd02ac4e0051a8072dde8f";
    "WINGIT_URL"="https://github.com/git-for-windows/git/releases/download/v2.37.3.windows.1/Git-2.37.3-64-bit.exe";
    "WINGIT_SHA256"="b0442f1b8ea40b6f94ef9a611121d2c204f6aa7f29c54315d2ce59876c3d134e";
    "SEVENZIP_VERSION"="19.0.0";
    "SEVENZIP_SHA256"="0f5d4dbbe5e55b7aa31b91e5925ed901fdf46a367491d81381846f05ad54c45e";
    
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
    "PYTHON_VERSION"="3.11.8";
    "PYTHON_SHA256"="fd3428eb6c80901b877d036ffa2be127ccad9bbe036a43f00fc96a48b724f9c7";
    "WIX_VERSION"="3.14.1";
    "WIX_SHA256"="6BF6D03D6923D9EF827AE1D943B90B42B8EBB1B0F68EF6D55F868FA34C738A29";
    "CMAKE_VERSION"="3.30.2";
    "CMAKE_SHA256"="31f799a9e7756305f74cd821970a793e599ead230925392886f45aed897a3c0e";
    "MSYS_VERSION"="20230318";
    "MSYS_SHA256"="83B95C0787810B06AE2E30420C70126D2269B4A64D0702FC3D6B2BF24FC6D72D";
    "NUGET_VERSION"="5.8.0";
    "NUGET_SHA256"="5c5b9c96165d3283b2cb9e5b65825d343e0e7139b9e70a250b4bb24c2285f3ba";
    "WINGET_VERSION"="1.6.5.0";
    "WINGET_SHA256"="2CCED75B1830246A78FF0E57F18133807F78BA484CCA2D369CBDDF490DDAC1AF";
    "EMBEDDED_PYTHON_2_VERSION"="2.7.17";
    "EMBEDDED_PYTHON_2_SHA256"="557ea6690c5927360656c003d3114b73adbd755b712a2911975dde813d6d7afb";
    "EMBEDDED_PYTHON_3_VERSION"="3.11.8";
    "EMBEDDED_PYTHON_3_SHA256"="8b016ed2f94cfc027fed172cbf1f6043f64519c6e9ad70b4565635192228b2b6";
    "EMBEDDED_PIP_VERSION"="20.3.4";
    "CODEQL_VERSION"="2.10.3";
    "CODEQL_HASH"="46f64e21c74f41210ea3f2c433d1dc622e3eb0690b42373a73fba82122b929a1";
    "NINJA_VERSION"="1.11.0";
    "NINJA_SHA256"="d0ee3da143211aa447e750085876c9b9d7bcdd637ab5b2c5b41349c617f22f3b";
    "GCLOUD_SDK_VERSION"="315.0.0";
    "GCLOUD_SDK_SHA256"="c9b283c9db4ed472111ccf32e6689fd467daf18ce3a77b8e601f9c646a83d86b";
    "CACERTS_VERSION"="2024-07-02";
    "CACERTS_HASH"="1bf458412568e134a4514f5e170a328d11091e071c7110955c9884ed87972ac9";
    "JAVA_VERSION"="17.0.8";
    "JAVA_SHA256"="db6e7e7506296b8a2338f6047fdc94bf4bbc147b7a3574d9a035c3271ae1a92b";
    "JSIGN_VERSION"="5.0";
    "WINSIGN_VERSION"="0.2.3";
    "WINSIGN_SHA256"="8091cd41e8e91b8a6b2ec8c2031b12ea4ca42897b972f9f46c2be6ae4c9961f7";
    "RUSTUP_VERSION"="1.26.0";
    "RUSTUP_SHA256"="365D072AC4EF47F8774F4D2094108035E2291A0073702DB25FA7797A30861FC9";
    "RUST_VERSION"="1.74.0";
    "CI_UPLOADER_VERSION"="2.38.1";
    "CI_UPLOADER_SHA256"="b8311e01cbe71ead8d64ff123eddde1d3df31b80a4bed200d17a41b88e873ed5";
    "CODECOV_VERSION"="v0.6.1";
    "CODECOV_SHA256"="6b95584fbb252b721b73ddfe970d715628879543d119f1d2ed08b073155f7d06";
}
