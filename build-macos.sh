# Description: Build script for macOS
#!/bin/bash

# get version from first argument
version=$1

if [ $MACOS_ARCH == "x86_64" ]
then
    arch -x86_64 /usr/local/bin/brew install libomp
    export OPENMP_PREFIX="/usr/local/opt/libomp"
else
    brew install libomp
    export OPENMP_PREFIX="/opt/homebrew/opt/libomp"
fi

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo

cmake --build build --config RelWithDebInfo

# install
cmake --install build

if [[ $USE_COREML == "off" ]]
then
    $archive_name="whispercpp-macos-$MACOS_ARCH-metal$METAL_STD-no-coreml-$version"
else
    $archive_name="whispercpp-macos-$MACOS_ARCH-metal$METAL_STD-$version"
fi

# compress the release folder
tar -czvf whispercpp-macos-$MACOS_ARCH-metal$METAL_STD-$version.tar.gz release
