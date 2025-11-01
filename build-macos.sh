# Description: Build script for macOS
#!/bin/bash

# get version from first argument
version=$1

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo

cmake --build build --config RelWithDebInfo

# install
cmake --install build

# compress the release folder
tar -czvf whispercpp-macos-$MACOS_ARCH-$version.tar.gz release
