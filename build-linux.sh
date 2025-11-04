# Description: Build script for linux
#!/bin/bash

# get version from first argument
version=$1

# check env var BUILD_WITH_ACCEL
if [ "$BUILD_WITH_ACCEL" = "cuda" ]; then
    echo "Building with CUDA acceleration"
    export CMAKE_ARGS="$CMAKE_ARGS -DWHISPERCPP_WITH_CUDA=ON"
elif [ "$BUILD_WITH_ACCEL" = "hipblas" ]; then
    echo "Building with hipblas acceleration"
    export CMAKE_ARGS="$CMAKE_ARGS -DWHISPERCPP_WITH_HIPBLAS=ON"
else
    echo "Building with generic acceleration"
fi

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo $CMAKE_ARGS

cmake --build build --config RelWithDebInfo

# install
cmake --install build

# compress the release folder
tar -czvf whispercpp-linux-$LINUX_ARCH-$BUILD_WITH_ACCEL-$version.tar.gz release
