Param(
    [string]$Version
)

# check env var BUILD_WITH_ACCEL
if ($env:BUILD_WITH_ACCEL -eq $null) {
    Write-Host "Please set env var BUILD_WITH_ACCEL to 'generic', 'nvidia', or 'amd'."
    exit
}

$env:CMAKE_TOOLCHAIN_FILE=""
$env:VCPKG_ROOT=""

# find the Vulkan SDK version path in C:\VulkanSDK\
$vulkanSdkPath = Get-ChildItem -Path "C:\VulkanSDK" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$env:VULKAN_SDK_PATH="$vulkanSdkPath"

$cmakeArgs = @()
if ($env:BUILD_WITH_ACCEL -eq "generic") {
    $zipFileName = "whispercpp-windows-generic-$Version.zip"
} elseif ($env:BUILD_WITH_ACCEL -eq "amd") {
    $cmakeArgs += ("-DWHISPERCPP_AMD=ON",
        "-DCMAKE_GENERATOR=Unix Makefiles", 
        "-DCMAKE_C_COMPILER='$env:HIP_PATH\bin\clang.exe'",
        "-DCMAKE_CXX_COMPILER='$env:HIP_PATH\bin\clang++.exe'")
    $zipFileName = "whispercpp-windows-amd-$Version.zip"
    $env:HIP_PLATFORM="amd"
} elseif ($env:BUILD_WITH_ACCEL -eq "nvidia") {
    $cmakeArgs += (
        "-DWHISPERCPP_NVIDIA=ON",
        "-DCMAKE_GENERATOR=Visual Studio 17 2022",
        "-DCUDA_TOOLKIT_ROOT_DIR=$env:CUDA_TOOLKIT_ROOT_DIR"
    )
    $zipFileName = "whispercpp-windows-nvidia-$Version.zip"
}

if ($env:RUNNER_TEMP) {
  $build_dir = "$env:RUNNER_TEMP\build"
} else {
  $build_dir = "build"
}

# configure
cmake -S . -B $build_dir -DCMAKE_BUILD_TYPE=RelWithDebInfo @cmakeArgs

cmake --build $build_dir --config RelWithDebInfo

# install
cmake --install $build_dir

# compress the release folder
Compress-Archive -Force -Path release -DestinationPath $zipFileName
