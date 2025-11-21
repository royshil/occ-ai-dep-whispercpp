# Whisper.cpp prebuilt binaries
Whisper.cpp prebuilt binaries for static and dynamic linking

## Building on Windows

You will need MSVS 2022 installed.

Set up environment variables, e.g.:

```powershell
> $env:BUILD_WITH_ACCEL="nvidia"
> $env:CUDA_TOOLKIT_ROOT_DIR="C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.5"
```

Acceleration options: `generic`, `nvidia` and `amd`

For `amd` make sure `$env:HIP_PATH` points to the HIP installation folder, e.g. where `$env:HIP_PATH\bin\clang.exe` would be located. See https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#hip for more details

The HIP installer can be downloaded from https://download.amd.com/developer/eula/rocm-hub/AMD-Software-PRO-Edition-24.Q3-Win10-Win11-For-HIP.exe.

You'll also need `make` which is most easily obtained by [installing Chocolatey](https://docs.chocolatey.org/en-us/choco/setup/) and then running `choco install make`

Run the build script:

```powershell
> ./Build-Windows.ps1 -Version 0.0.11
```

## Building on Mac OS

Set the `MACOS_ARCH` env variable to `x86_64` or `arm64`:

```bash
$ export MACOS_ARCH=x86_64
```

Set the `METAL_STD` env variable to `2.4` (for MacOS 12.0+), `3.0` (for MacOS 13.0+), `3.1` (for MacOS 14.0+), or `3.2` (for MacOS 15.0+)

```bash
$ export METAL_STD=2.4
```

To disable CoreML support, set the `USE_COREML` env var to `off`

```bash
$ export USE_COREML=off
```

Run the build script:

```bash
$ ./build-macos.sh 0.0.11
```

## Building on Linux

Set up environment variables, e.g.:

```powershell
> $env:BUILD_WITH_ACCEL="nvidia"
> $env:CUDA_TOOLKIT_ROOT_DIR="C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.5"
```

Acceleration options: `generic`, `nvidia` and `amd`

For `amd` install the ROCm SDK v6.4.2
For `nvidia` install the CUDA SDK v12.8.0

For all variants install the Vulkan and OpenCL SDKs, as well as OpenBLAS

Run the build script:

```bash
$ ./build-linux.sh 0.0.11
```
