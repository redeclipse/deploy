#!/bin/sh

CI_DIR=/ci
MANIFEST_DIR=${CI_DIR}/sys_manifests
ARCHIVE_DIR=${CI_DIR}/sys_archives
SDK_ARCHIVE_DIR=${ARCHIVE_DIR}/sdk
MSVC_ARCHIVE_DIR=${ARCHIVE_DIR}/msvc
SYS_DIR=${SYS_DIR}

NUMJOBS=$(nproc)
SRC_DIR="${CI_DIR}/game/src"
OUTPUT_DIR="${CI_DIR}/output"

build_fail() {
    echo "Build failure: $1"
    exit 1
}

# Unpack Windows SDK and MSVC packages

unzip -q -n ${SDK_ARCHIVE_DIR}/winsdk.nupkg -d ${SYS_DIR}/winsdk && \
    unzip -q -n ${SDK_ARCHIVE_DIR}/winsdk_x64.nupkg -d ${SYS_DIR}/winsdk_lib ||
    build_fail "Failed to unpack Windows SDK packages"

for pkg in ${MSVC_ARCHIVE_DIR}/*.vsix; do
    unzip -q -n ${pkg} -d ${SYS_DIR}/msvc ||
        build_fail "Failed to unpack MSVC packages"
done

# Build

MSVC_VER=$(ls ${SYS_DIR}/msvc/Contents/VC/Tools/MSVC/)
SDK_VER=$(ls ${SYS_DIR}/winsdk/c/Include/)

export MSVC_DIR="${SYS_DIR}/msvc/Contents/VC/Tools/MSVC/$MSVC_VER"
export WINKIT_INC_DIR="${SYS_DIR}/winsdk/c/Include/$SDK_VER"
export WINKIT_LIB_DIR="${SYS_DIR}/winsdk_lib/c/"

export PLATFORM_BUILD=${PLATFORM_BUILD:-""}
export PLATFORM_BRANCH=${PLATFORM_BRANCH:-""}
export PLATFORM_REVISION=${PLATFORM_REVISION:-""}

cat << EOF



#######################################
#                                     #
# Building for: Windows x86_64 (MSVC) #
#                                     #
#######################################



EOF

make -C ${SRC_DIR} clean ||
    build_fail "Build cleanup failed"
sleep 1

make \
    PLATFORM="x86_64-pc-windows-msvc" \
    PLATFORM_BIN="amd64" \
    WANT_DISCORD=1 \
    WANT_STEAM=1 \
    INSTDIR="${OUTPUT_DIR}/windows/bin/amd64" \
    -O -j ${NUMJOBS} \
    -C ${SRC_DIR} install ||
    build_fail "Windows x86_64 build failed"

cat << EOF



####################################
#                                  #
# Building for: Linux x86_64 (GNU) #
#                                  #
####################################



EOF

make -C ${SRC_DIR} clean ||
    build_fail "Build cleanup failed"
sleep 1

make \
    PLATFORM="linux64" \
    PLATFORM_BIN="amd64" \
    WANT_DISCORD=1 \
    WANT_STEAM=1 \
    INSTDIR="${OUTPUT_DIR}/linux/bin/amd64" \
    -O -j ${NUMJOBS} \
    -C ${SRC_DIR} install ||
    build_fail "Linux x86_64 build failed"

cat << EOF



##################
#                #
# Build finished #
#                #
##################



EOF
