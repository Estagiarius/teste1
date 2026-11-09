cmake_minimum_required(VERSION 3.10)
project(native_proxy)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find mbedTLS
find_package(MbedTLS REQUIRED)

# Executable target
add_executable(proxy_tls13 native-proxy/proxy_tls13.cpp)

# Link libraries
target_link_libraries(proxy_tls13 PRIVATE mbedtls mbedcrypto mbedx509 pthread)

# Ensure threading
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
target_link_libraries(proxy_tls13 PRIVATE Threads::Threads)
