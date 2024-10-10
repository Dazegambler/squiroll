set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR i686)

set(PREFIX $ENV{HOME}/.xwin-cache/splat)
set(CLANG_SUFFIX "-18" CACHE STRING "")

# specify the cross compiler
set(CMAKE_C_COMPILER clang-cl${CLANG_SUFFIX} )
set(CMAKE_CXX_COMPILER clang-cl${CLANG_SUFFIX})
set(CMAKE_RC_COMPILER llvm-rc${CLANG_SUFFIX})
set(CMAKE_LINKER lld-link${CLANG_SUFFIX})
set(CMAKE_MT llvm-mt${CLANG_SUFFIX})

set(CMAKE_C_FLAGS "-fuse-ld=lld -m32")
set(CMAKE_CXX_FLAGS "-fuse-ld=lld -m32")

# # skip c/cxx compiler checks
# set(CMAKE_C_COMPILER_WORKS 1)
# set(CMAKE_CXX_COMPILER_WORKS 1)

include_directories(
    SYSTEM
    ${PREFIX}/crt/include
    ${PREFIX}/sdk/include/shared
    ${PREFIX}/sdk/include/ucrt
    ${PREFIX}/sdk/include/um
)

link_directories(
    ${PREFIX}/crt/lib/x86
    ${PREFIX}/sdk/lib/ucrt/x86
    ${PREFIX}/sdk/lib/um/x86
)
