# Description: Build script for macOS
#!/bin/bash

# get version from first argument
version=$1
verbose=$2

if [ $MACOS_ARCH == "x86_64" ]
then
    arch -x86_64 /usr/local/bin/brew install libomp
    export OPENMP_PREFIX="/usr/local/opt/libomp"
else
    brew install libomp
    export OPENMP_PREFIX="/opt/homebrew/opt/libomp"
fi

if [[ $verbose == "--verbose" ]]
then
    extra_configure_args="--debug-output"
    extra_build_args="--verbose"
fi

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug $extra_configure_args

cmake --build build --config Debug $extra_build_args

# install
cmake --install build

if [[ $USE_COREML == "off" ]]
then
    archive_name="whispercpp-macos-$MACOS_ARCH-metal$METAL_STD-no-coreml-$version"
else
    archive_name="whispercpp-macos-$MACOS_ARCH-metal$METAL_STD-$version"
fi

# compress the release folder
tar -czvf $archive_name.tar.gz release
