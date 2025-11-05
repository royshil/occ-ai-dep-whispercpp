# Description: Build script for linux
#!/bin/bash

# get version from first argument
version=$1

# check env var BUILD_WITH_ACCEL
if [ "$BUILD_WITH_ACCEL" = "nvidia" ]; then
    echo "Building with NVidia specific acceleration options"
    export CMAKE_ARGS="$CMAKE_ARGS -DWHISPERCPP_NVIDIA=ON -DCMAKE_CUDA_COMPILER=/usr/local/bin/nvcc"
elif [ "$BUILD_WITH_ACCEL" = "amd" ]; then
    echo "Building with AMD specific acceleration options"
    export CMAKE_ARGS="$CMAKE_ARGS -DWHISPERCPP_AMD=ON"
else
    echo "Building with generic acceleration options"
fi

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo $CMAKE_ARGS

cmake --build build --config RelWithDebInfo

# install
cmake --install build

# compress the release folder
tar -czvf whispercpp-linux-$LINUX_ARCH-$BUILD_WITH_ACCEL-$version.tar.gz release
