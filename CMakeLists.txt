cmake_minimum_required(VERSION 3.21)

project(Whispercpp_prebuilt)

include(ExternalProject)
include(FetchContent)

option(WHISPERCPP_NVIDIA "Build Whisper with CUDA support" OFF)
option(WHISPERCPP_AMD "Build Whisper with hipBLAS support" OFF)

set(CMAKE_OSX_ARCHITECTURES_ "$ENV{MACOS_ARCH}")

set(Whispercpp_Build_GIT_TAG "v1.8.2")

if(${CMAKE_BUILD_TYPE} STREQUAL Release OR ${CMAKE_BUILD_TYPE} STREQUAL
                                           RelWithDebInfo)
  set(Whispercpp_BUILD_TYPE RelWithDebInfo)
else()
  set(Whispercpp_BUILD_TYPE Debug)
endif()

# List supported ROCm GPU targets in ROCm 6.4.2, and also some unsupported ones that might work
# See https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html and https://rocm.docs.amd.com/en/docs-6.4.2/reference/gpu-arch-specs.html
# gfx950 is supported in 7.1.0 but not 6.4.2 that we're using
list(APPEND SUPPORTED_AMDGPU_TARGETS gfx908 gfx90a gfx942 gfx1030 gfx1100 gfx1200 gfx1201)
list(APPEND UNSUPPORTED_AMDGPU_TARGETS gfx803 gfx900 gfx906 gfx950 gfx1010 gfx1011 gfx1012 gfx1031 gfx1032 gfx1101 gfx1102 gfx1150 gfx1151 gfx1152)
list(APPEND AMDGPU_TARGETS ${SUPPORTED_AMDGPU_TARGETS} ${UNSUPPORTED_AMDGPU_TARGETS})
list(JOIN AMDGPU_TARGETS ";" AMDGPU_TARGETS_STRING)
message(STATUS "GPU TARGETS: ${AMDGPU_TARGETS_STRING}")

if(UNIX AND NOT APPLE)
  # On linux add the `-fPIC` flag to the compiler
  set(WHISPER_EXTRA_CXX_FLAGS "-fPIC")

  list(
    APPEND
    WHISPER_ADDITIONAL_CMAKE_ARGS
    # OpenBLAS
    -DGGML_BLAS=ON
    -DGGML_BLAS_VENDOR=OpenBLAS
    # Vulkan
    -DGGML_VULKAN=ON
    # OpenCL
    -DGGML_OPENCL=ON
    -DGGML_OPENCL_EMBED_KERNELS=ON
    -DGGML_OPENCL_USE_ADRENO_KERNELS=OFF
    # SYCL -DGGML_SYCL=ON Dynamic backends
    -DGGML_NATIVE=OFF
    -DGGML_BACKEND_DL=ON
    -DGGML_CPU_ALL_VARIANTS=ON)
  set(CMAKE_PARALLEL --parallel)

  if(WHISPERCPP_NVIDIA)
    list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_CUDA=ON
         -DCMAKE_CUDA_ARCHITECTURES=all
         -DCMAKE_CUDA_COMPILER=${CMAKE_CUDA_COMPILER})
    # -DGGML_SYCL_TARGET=NVIDIA)
    set(CMAKE_PARALLEL "--parallel 3")
  elseif(WHISPERCPP_AMD)
    # cmake_path(SET HIP_PATH_STR NORMALIZE "$ENV{HIP_PATH}")
    # set(WHISPER_ADDITIONAL_ENV "CMAKE_PREFIX_PATH=${HIP_PATH_STR}")
    
    list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DCMAKE_C_COMPILER=hipcc
         -DCMAKE_CXX_COMPILER=hipcc -DGGML_HIP=ON)
    list(APPEND WHISPER_ADDITIONAL_CMAKE_CACHE_ARGS -DGPU_TARGETS:STRING=${AMDGPU_TARGETS})
    set(WHISPER_EXTRA_CXX_FLAGS "-fPIC -g")
    # -DGGML_SYCL_TARGET=AMD)
  endif()
endif()

if(APPLE)
  # check the "MACOS_ARCH" env var to figure out if this is x86_64 or arm64
  if(NOT DEFINED ENV{MACOS_ARCH})
    message(
      FATAL_ERROR
        "The MACOS_ARCH environment variable is not set. Please set it to either `x86_64` or `arm64`"
    )
  endif(NOT DEFINED ENV{MACOS_ARCH})

  # cmake-format: off
  # note: use 'ios-metal1.0' for 'Metal 1.0 (iOS)' standard
  # note: use 'ios-metal1.1' for 'Metal 1.1 (iOS)' standard
  # note: use 'ios-metal1.2' for 'Metal 1.2 (iOS)' standard
  # note: use 'ios-metal2.0' for 'Metal 2.0 (iOS)' standard
  # note: use 'ios-metal2.1' for 'Metal 2.1 (iOS)' standard
  # note: use 'ios-metal2.2' for 'Metal 2.2 (iOS)' standard
  # note: use 'ios-metal2.3' for 'Metal 2.3 (iOS)' standard
  # note: use 'ios-metal2.4' for 'Metal 2.4 (iOS)' standard
  # note: use 'macos-metal1.0' or 'osx-metal1.0' for 'Metal 1.0 (macOS)' standard
  # note: use 'macos-metal1.1' or 'osx-metal1.1' for 'Metal 1.1 (macOS)' standard
  # note: use 'macos-metal1.2' or 'osx-metal1.2' for 'Metal 1.2 (macOS)' standard
  # note: use 'macos-metal2.0' or 'osx-metal2.0' for 'Metal 2.0 (macOS)' standard
  # note: use 'macos-metal2.1' for 'Metal 2.1 (macOS)' standard
  # note: use 'macos-metal2.2' for 'Metal 2.2 (macOS)' standard
  # note: use 'macos-metal2.3' for 'Metal 2.3 (macOS)' standard
  # note: use 'macos-metal2.4' for 'Metal 2.4 (macOS)' standard
  # note: use 'metal3.0' for 'Metal 3.0' standard
  # note: use 'metal3.1' for 'Metal 3.1' standard
  # note: use 'metal3.2' for 'Metal 3.2' standard
  # cmake-format: on

  # Presumably need newer XCode and/or a Tahoe (26) runner to get standard v4

  option(METAL_STD "Which Metal version to target" macos-metal2.4)
  option(USE_COREML "Enable CoreML support" ON)

  if(DEFINED ENV{METAL_STD})
    if($ENV{METAL_STD} STREQUAL 2.4)
      set(METAL_STD "macos-metal$ENV{METAL_STD}")
      set(EMBED_METAL OFF)
      list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0)
    elseif($ENV{METAL_STD} STREQUAL 3.0)
      set(METAL_STD "metal$ENV{METAL_STD}")
      set(EMBED_METAL OFF)
      list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DCMAKE_OSX_DEPLOYMENT_TARGET=13.3)
    elseif($ENV{METAL_STD} STREQUAL 3.1)
      set(METAL_STD "metal$ENV{METAL_STD}")
      set(EMBED_METAL OFF)
      list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0)
    elseif($ENV{METAL_STD} STREQUAL 3.2)
      set(METAL_STD "metal$ENV{METAL_STD}")
      set(EMBED_METAL OFF)
      list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0)
    elseif($ENV{METAL_STD} STREQUAL embedded)
      set(EMBED_METAL ON)
      list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0)
    else()
      message(FATAL_ERROR "Unsupported Metal standard $ENV{METAL_STD}")
    endif()
  endif()

  if(DEFINED ENV{USE_COREML})
    set(USE_COREML $ENV{USE_COREML})
  endif()

  list(
    APPEND
    WHISPER_ADDITIONAL_CMAKE_ARGS
    -DCMAKE_PREFIX_PATH=$ENV{OPENMP_PREFIX}
    -DGGML_METAL=ON
    -DGGML_METAL_MACOSX_VERSION_MIN=12.0
    -DGGML_METAL_STD=${METAL_STD}
    -DGGML_METAL_EMBED_LIBRARY=OFF
    -DGGML_NATIVE=OFF
    -DGGML_BACKEND_DL=ON)
  
  if(${EMBED_METAL})
    list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_METAL_EMBED_LIBRARY=ON)
  else()
    list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_METAL_EMBED_LIBRARY=OFF -DGGML_METAL_STD=${METAL_STD})
  endif()

  if(${USE_COREML})
    list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DWHISPER_COREML=ON
         -DWHISPER_COREML_ALLOW_FALLBACK=ON)
  endif()

  set(WHISPER_EXTRA_CXX_FLAGS
      "-Wno-shorten-64-to-32 -Wno-unused-parameter -Wno-unused-function -Wno-unguarded-availability-new"
  )
  set(CMAKE_PARALLEL --parallel)

  list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_CPU_ALL_VARIANTS=ON)
endif()

if(WIN32)
  if(NOT WHISPERCPP_AMD)
    add_compile_options("$<$<NOT:$<CONFIG:Debug>>:/Zi>")
    add_link_options("$<$<NOT:$<CONFIG:Debug>>/DEBUG">)
    add_link_options("$<$<NOT:$<CONFIG:Debug>>/OPT:REF">)
    add_link_options("$<$<NOT:$<CONFIG:Debug>>/OPT:ICF">)
  endif()

  # Build with OpenBLAS for all configurations
  set(OpenBLAS_URL
      "https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.26/OpenBLAS-0.3.26-x64.zip"
  )
  set(OpenBLAS_SHA256
      "859C510A962A30EF1B01AA93CDE26FDB5FB1050F94AD5AB2802EBA3731935E06")
  FetchContent_Declare(
    OpenBLAS
    URL ${OpenBLAS_URL}
    URL_HASH SHA256=${OpenBLAS_SHA256}
    DOWNLOAD_EXTRACT_TIMESTAMP true)
  FetchContent_MakeAvailable(OpenBLAS)
  set(OpenBLAS_DIR ${openblas_SOURCE_DIR})
  message(STATUS "OpenBLAS_DIR: ${OpenBLAS_DIR}")
  set(WHISPER_ADDITIONAL_ENV "OPENBLAS_PATH=${openblas_SOURCE_DIR}")
  list(
    APPEND
    WHISPER_ADDITIONAL_CMAKE_ARGS
    -DGGML_BLAS=ON
    -DGGML_BLAS_VENDOR=OpenBLAS
    -DBLAS_LIBRARIES=${OpenBLAS_DIR}/lib/libopenblas.lib
    -DBLAS_INCLUDE_DIRS=${OpenBLAS_DIR}/include)
  set(WHISPER_CMAKE_GENERATOR ${CMAKE_GENERATOR})

  if(NOT DEFINED ENV{VULKAN_SDK_PATH})
    message(
      FATAL_ERROR
        "VULKAN_SDK_PATH is not set. Please set it to the root directory of your VulkanSDK installation, e.g. `C:/VulkanSDK/1.3.296.0`"
    )
  endif()

  # Build with VULKAN
  list(APPEND WHISPER_ADDITIONAL_ENV "VULKAN_SDK=$ENV{VULKAN_SDK_PATH}")
  list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_VULKAN=ON)

  if(WHISPERCPP_NVIDIA)
    # Build with CUDA
    list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_CUDA=ON
         -DCMAKE_CUDA_ARCHITECTURES=all)
  elseif(WHISPERCPP_AMD)
    # Build with hipBLAS
    if(NOT DEFINED ENV{HIP_PATH})
      message(
        FATAL_ERROR
          "HIP_PATH is not set. Please set it to the root directory of your HIP installation, e.g. `C:/Program Files/ROCm`"
      )
    endif(NOT DEFINED ENV{HIP_PATH})

    # TODO - turn GPU targets into a list and generate these offload-arch flags rather than hardcoding them
    foreach(TARGET ${AMDGPU_TARGETS})
      list(APPEND AMDGPU_TARGET_FLAGS "--offload-arch=${TARGET}")
    endforeach(TARGET ${AMDGPU_TARGETS})
    list(JOIN AMDGPU_TARGET_FLAGS " " AMDGPU_TARGET_FLAGS_STRING)
    set(WHISPER_EXTRA_CXX_FLAGS "-g --no-warnings ${AMDGPU_TARGET_FLAGS_STRING}")
    cmake_path(SET HIP_PATH_STR NORMALIZE "$ENV{HIP_PATH}")
    list(APPEND WHISPER_ADDITIONAL_ENV "CMAKE_PREFIX_PATH=${HIP_PATH_STR}")
    list(APPEND WHISPER_ADDITIONAL_CMAKE_ARGS -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
         -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DGGML_HIP=ON)
  endif()

  ExternalProject_Add(
    Whispercpp_Build
    DOWNLOAD_EXTRACT_TIMESTAMP true
    GIT_REPOSITORY https://github.com/ggerganov/whisper.cpp.git
    GIT_TAG ${Whispercpp_Build_GIT_TAG}
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --parallel --config
                  ${Whispercpp_BUILD_TYPE} --verbose
    BUILD_BYPRODUCTS
      <INSTALL_DIR>/lib/static/${CMAKE_STATIC_LIBRARY_PREFIX}whisper${CMAKE_STATIC_LIBRARY_SUFFIX}
      <INSTALL_DIR>/bin/${CMAKE_SHARED_LIBRARY_PREFIX}whisper${CMAKE_SHARED_LIBRARY_SUFFIX}
      <INSTALL_DIR>/bin/${CMAKE_SHARED_LIBRARY_PREFIX}whisper.pdb
      <INSTALL_DIR>/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}whisper${CMAKE_IMPORT_LIBRARY_SUFFIX}
    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR> --config
                    ${Whispercpp_BUILD_TYPE}
    CMAKE_CACHE_ARGS ${WHISPER_ADDITIONAL_CMAKE_CACHE_ARGS}
    CONFIGURE_COMMAND
      ${CMAKE_COMMAND} -E env ${WHISPER_ADDITIONAL_ENV} ${CMAKE_COMMAND}
      <SOURCE_DIR> -B <BINARY_DIR> -G ${WHISPER_CMAKE_GENERATOR}
      -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
      -DCMAKE_BUILD_TYPE=${Whispercpp_BUILD_TYPE}
      -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
      -DCMAKE_CXX_FLAGS=${WHISPER_EXTRA_CXX_FLAGS}
      -DCMAKE_C_FLAGS=${WHISPER_EXTRA_CXX_FLAGS} -DBUILD_SHARED_LIBS=ON
      -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=OFF
      -DWHISPER_BUILD_SERVER=OFF -DGGML_NATIVE=OFF -DGGML_BACKEND_DL=ON
      -DGGML_CPU_ALL_VARIANTS=ON -DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/cmake
      ${WHISPER_ADDITIONAL_CMAKE_ARGS})
else()
  # On Linux and MacOS build a shared Whisper library
  ExternalProject_Add(
    Whispercpp_Build
    DOWNLOAD_EXTRACT_TIMESTAMP true
    GIT_REPOSITORY https://github.com/ggerganov/whisper.cpp.git
    GIT_TAG ${Whispercpp_Build_GIT_TAG}
    PATCH_COMMAND
      git apply
      ${CMAKE_SOURCE_DIR}/patches/whispercpp-patches.patch
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> ${CMAKE_PARALLEL}
                  --config ${Whispercpp_BUILD_TYPE} --verbose
    BUILD_BYPRODUCTS
      <INSTALL_DIR>/lib/${CMAKE_SHARED_LIBRARY_PREFIX}whisper${CMAKE_SHARED_LIBRARY_SUFFIX}
    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR> --config
                    ${Whispercpp_BUILD_TYPE}
    CMAKE_CACHE_ARGS ${WHISPER_ADDITIONAL_CMAKE_CACHE_ARGS}
    CONFIGURE_COMMAND
      ${CMAKE_COMMAND} -E env ${WHISPER_ADDITIONAL_ENV} ${CMAKE_COMMAND}
      <SOURCE_DIR> -B <BINARY_DIR> -G ${CMAKE_GENERATOR}
      -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
      -DCMAKE_BUILD_TYPE=${Whispercpp_BUILD_TYPE}
      -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
      -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES_}
      -DCMAKE_CXX_FLAGS=${WHISPER_EXTRA_CXX_FLAGS}
      -DCMAKE_C_FLAGS=${WHISPER_EXTRA_CXX_FLAGS} -DBUILD_SHARED_LIBS=ON
      -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=OFF
      -DWHISPER_BUILD_SERVER=OFF ${WHISPER_ADDITIONAL_CMAKE_ARGS})
endif(WIN32)

ExternalProject_Get_Property(Whispercpp_Build SOURCE_DIR)
ExternalProject_Get_Property(Whispercpp_Build INSTALL_DIR)
ExternalProject_Get_Property(Whispercpp_Build BINARY_DIR)

# add the Whisper library to the link line
if(WIN32)
  # copy lib/ include/ and bin/ from ${INSTALL_DIR} to the release directory in
  # the root of the project
  install(DIRECTORY ${INSTALL_DIR}/lib DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${INSTALL_DIR}/include
          DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${INSTALL_DIR}/bin DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-base.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-blas.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/whisper.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-cpu.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-cpu-alderlake.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-cpu-haswell.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-cpu-icelake.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-cpu-sandybridge.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-cpu-skylakex.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-cpu-sse42.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)
  install(
    FILES ${BINARY_DIR}/bin/${Whispercpp_BUILD_TYPE}/ggml-cpu-x64.pdb
    DESTINATION ${CMAKE_SOURCE_DIR}/release/bin
    OPTIONAL)

  if(WHISPERCPP_AMD)
    message(STATUS "Setup HIP DLLs installation")
    set(HIPBLAS_DLLS
        "${HIP_PATH_STR}/bin/hipblas.dll" "${HIP_PATH_STR}/bin/rocblas.dll"
        "${HIP_PATH_STR}/bin/amdhip64_6.dll"
        "${HIP_PATH_STR}/bin/amd_comgr_2.dll")
    install(FILES ${HIPBLAS_DLLS} DESTINATION ${CMAKE_SOURCE_DIR}/release/bin)
  elseif(WHISPERCPP_NVIDIA)
    # Check that CUDA_TOOLKIT_ROOT_DIR is set
    if(NOT DEFINED CUDA_TOOLKIT_ROOT_DIR)
      message(
        FATAL_ERROR
          "CUDA_TOOLKIT_ROOT_DIR is not set. Please set it to the root directory of your CUDA "
          "installation, e.g. `C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.4`"
      )
    endif(NOT DEFINED CUDA_TOOLKIT_ROOT_DIR)

    # normalize CUDA path with file(TO_CMAKE_PATH)
    file(TO_CMAKE_PATH ${CUDA_TOOLKIT_ROOT_DIR} CUDA_TOOLKIT_ROOT_DIR)

    # find the CUDA DLLs for cuBLAS in the bin directory of the CUDA
    # installation e.g. cublas64_NN.dll
    file(GLOB CUBLAS_DLLS "${CUDA_TOOLKIT_ROOT_DIR}/bin/cublas64_*.dll")

    # find cublasLt DLL, e.g. cublasLt64_11.dll
    file(GLOB CUBLASLT_DLLS "${CUDA_TOOLKIT_ROOT_DIR}/bin/cublasLt64_*.dll")

    # find cudart DLL, e.g. cudart64_110.dll
    file(GLOB CUDART_DLLS "${CUDA_TOOLKIT_ROOT_DIR}/bin/cudart64_*.dll")

    # if any of the files cannot be found, abort
    if(NOT CUBLAS_DLLS
       OR NOT CUBLASLT_DLLS
       OR NOT CUDART_DLLS)
      message(
        FATAL_ERROR
          "Could not find cuBLAS, cuBLASLt or cuDART DLLs in ${CUDA_TOOLKIT_ROOT_DIR}/bin"
      )
    endif()

    # copy the DLLs to the OBS plugin directory
    install(FILES ${CUBLAS_DLLS} ${CUBLASLT_DLLS} ${CUDART_DLLS}
            DESTINATION ${CMAKE_SOURCE_DIR}/release/bin)
  endif()

  message(STATUS "Install OpenBLAS DLLs")

  # add openblas to the link line
  install(DIRECTORY ${OpenBLAS_DIR}/lib DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${OpenBLAS_DIR}/include
          DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${OpenBLAS_DIR}/bin DESTINATION ${CMAKE_SOURCE_DIR}/release)
else()
  # copy lib/ include/ and bin/ from ${INSTALL_DIR} to the release directory in
  # the root of the project
  install(DIRECTORY ${INSTALL_DIR}/lib DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${INSTALL_DIR}/bin DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${SOURCE_DIR}/include
          DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${SOURCE_DIR}/ggml/include
          DESTINATION ${CMAKE_SOURCE_DIR}/release)

  if(APPLE)
    # copy the CoreML library to the release directory
    install(
      FILES
        ${BINARY_DIR}/src/${CMAKE_SHARED_LIBRARY_PREFIX}whisper.coreml${CMAKE_SHARED_LIBRARY_SUFFIX}
      DESTINATION ${CMAKE_SOURCE_DIR}/release/lib
      OPTIONAL)

    # Fix libomp linking and copy it to the release
    if($ENV{MACOS_ARCH} STREQUAL x86_64)
      list(APPEND CPU_BACKENDS
        libggml-cpu-x64.so
        libggml-cpu-sse42.so
        libggml-cpu-sandybridge.so
        libggml-cpu-haswell.so
        libggml-cpu-skylakex.so
        libggml-cpu-icelake.so
        libggml-cpu-alderlake.so
        libggml-cpu-sapphirerapids.so)
    else()
      list(APPEND CPU_BACKENDS
        libggml-cpu-apple_m1.so
        libggml-cpu-apple_m2_m3.so
        libggml-cpu-apple_m4.so)
    endif()
    # Fix libomp and Accelerate load paths
    foreach(CPU_BACKEND ${CPU_BACKENDS})
      add_custom_command(
        TARGET Whispercpp_Build
        POST_BUILD
        COMMAND
          ${CMAKE_INSTALL_NAME_TOOL} -change "$ENV{OPENMP_PREFIX}/lib/libomp.dylib"
          "@loader_path/../Frameworks/libomp.dylib"
          "${INSTALL_DIR}/bin/${CPU_BACKEND}")
    endforeach(CPU_BACKEND ${CPU_BACKENDS})

    install(FILES $ENV{OPENMP_PREFIX}/lib/libomp.dylib
            DESTINATION ${CMAKE_SOURCE_DIR}/release/lib)
    file(GLOB LIBOMP_HEADERS "$ENV{OPENMP_PREFIX}/include/*.h")
    install(FILES ${LIBOMP_HEADERS}
            DESTINATION ${CMAKE_SOURCE_DIR}/release/include)

  else()
    install(
      DIRECTORY ${INSTALL_DIR}/lib64
      DESTINATION ${CMAKE_SOURCE_DIR}/release
      OPTIONAL)
    file(GLOB LIBS_IN_LIB "${INSTALL_DIR}/lib/*${CMAKE_SHARED_LIBRARY_SUFFIX}")
    install(
      FILES ${LIBS_IN_LIB}
      DESTINATION ${CMAKE_SOURCE_DIR}/release/lib64
      OPTIONAL)
    file(GLOB LIBS_IN_LIB64
         "${INSTALL_DIR}/lib64/*${CMAKE_SHARED_LIBRARY_SUFFIX}")
    install(
      FILES ${LIBS_IN_LIB64}
      DESTINATION ${CMAKE_SOURCE_DIR}/release/lib
      OPTIONAL)
  endif()
endif(WIN32)
