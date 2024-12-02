set(CMAKE_BUILD_TYPE RelWithDebInfo)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_C_COMPILER zig cc -target x86_64-linux-musl)
set(CMAKE_CXX_COMPILER zig c++ -target x86_64-linux-musl)
set(CMAKE_FIND_ROOT_PATH /opt/datadog/embedded)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
