$SoftwareTable = @{
    "GIT_VERSION"="2.26.2";
    "GIT_SHA256"="2dfbb1c46547c70179442a92b8593d592292b8bce2fd02ac4e0051a8072dde8f";
    "WINGIT_URL"="https://github.com/git-for-windows/git/releases/download/v2.37.3.windows.1/Git-2.37.3-64-bit.exe";
    "WINGIT_SHA256"="b0442f1b8ea40b6f94ef9a611121d2c204f6aa7f29c54315d2ce59876c3d134e";
    "SEVENZIP_VERSION"="19.0.0";
    "SEVENZIP_SHA256"="0f5d4dbbe5e55b7aa31b91e5925ed901fdf46a367491d81381846f05ad54c45e";

    ## VisualStudio build tools for containers
    # https://learn.microsoft.com/en-us/visualstudio/releases/2019/history
    "VS2017BUILDTOOLS_VERSION"="16.11.34";
    "VS2017BUILDTOOLS_DOWNLOAD_URL"="https://download.visualstudio.microsoft.com/download/pr/30682086-8872-4c7d-b066-0446b278141b/6cc639a464629b62ece2b4b786880bd213ee371d89ffc7717dc08b7f68644f38/vs_BuildTools.exe";

    # Get-FileHash -Algorithm SHA256 -InputStream ([System.Net.WebClient]::new().OpenRead('https://download.visualstudio.microsoft.com/download/pr/30682086-8872-4c7d-b066-0446b278141b/6cc639a464629b62ece2b4b786880bd213ee371d89ffc7717dc08b7f68644f38/vs_BuildTools.exe'))
    "VS2017BUILDTOOLS_SHA256"="6CC639A464629B62ECE2B4B786880BD213EE371D89FFC7717DC08B7F68644F38";

    ## VisualStudio IDE
    # https://learn.microsoft.com/en-us/visualstudio/releases/2019/history
    "VS2019INSTALLER_DOWNLOAD_URL"="https://download.visualstudio.microsoft.com/download/pr/3a7354bc-d2e4-430f-92d0-9abd031b5ee5/d9fc228ea71a98adc7bc5f5d8e8800684c647e955601ed721fcb29f74ace7536/vs_Community.exe";
    "VS2019INSTALLER_SHA256"="d9fc228ea71a98adc7bc5f5d8e8800684c647e955601ed721fcb29f74ace7536";

    "RUBY_VERSION"="2.6.6-1";
    "RUBY_SHA256"="fbdf77a3e1fa36e25cf0af1303ac76f67dec7a6f739a829784a299702cad1492";
    "PYTHON_VERSION"="3.11.8";
    "PYTHON_SHA256"="fd3428eb6c80901b877d036ffa2be127ccad9bbe036a43f00fc96a48b724f9c7";
    "WIX_VERSION"="3.11.2";
    "WIX_SHA256"="32bb76c478fcb356671d4aaf006ad81ca93eea32c22a9401b168fc7471feccd2";
    "CMAKE_VERSION"="3.23.0";
    "CMAKE_SHA256"="1e772025844f1cc648d28f42090038e5ca5cf72e2889de26d8d05ee25da17061";
    "MSYS_VERSION"="20230318";
    "MSYS_SHA256"="83B95C0787810B06AE2E30420C70126D2269B4A64D0702FC3D6B2BF24FC6D72D";
    "NUGET_VERSION"="5.8.0";
    "NUGET_SHA256"="5c5b9c96165d3283b2cb9e5b65825d343e0e7139b9e70a250b4bb24c2285f3ba";
    "WINGET_VERSION"="1.6.1.0";
    "WINGET_SHA256"="EC84371949ECAD3C5C59D49DEAA4AF6BFB017CC81216A7B1F740A480341F44C3";
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
    "CACERTS_VERSION"="2024-03-11";
    "CACERTS_HASH"="1794c1d4f7055b7d02c2170337b61b48a2ef6c90d77e95444fd2596f4cac609f";
    "JAVA_VERSION"="17.0.8";
    "JAVA_SHA256"="db6e7e7506296b8a2338f6047fdc94bf4bbc147b7a3574d9a035c3271ae1a92b";
    "JSIGN_VERSION"="5.0";
    "WINSIGN_VERSION"="0.2.0";
    "WINSIGN_SHA256"="760aa4e3bf12b48ba134f72dda815e98ec628f84420d0ef1bdf4b0185b90193a";
    "RUSTUP_VERSION"="1.26.0";
    "RUSTUP_SHA256"="365D072AC4EF47F8774F4D2094108035E2291A0073702DB25FA7797A30861FC9";
    "RUST_VERSION"="1.74.0";
    "CI_UPLOADER_VERSION"="2.33.0";
    "CI_UPLOADER_SHA256"="7b85c3c858afe65554090a801831f2f8107a4d69567623c0ece5de6b9bb126c0";
    "CODECOV_VERSION"="v0.6.1";
    "CODECOV_SHA256"="6b95584fbb252b721b73ddfe970d715628879543d119f1d2ed08b073155f7d06";
}
