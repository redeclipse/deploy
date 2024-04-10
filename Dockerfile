FROM ubuntu:focal



###################
# COMMON PACKAGES #
###################



RUN apt update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt update && \
    apt-get install -y \
    jq \
    unzip \
    wget \
    lsb-release \
    gnupg \
    gcc-13 \
    g++-13 \
    make

ENV CI_DIR=/ci
WORKDIR ${CI_DIR}



####################
# WINDOWS PACKAGES #
####################



ENV SDK_VER=10.0.22621.3233
ENV VS_VER=17
ENV LLVM_VER=18

RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh ${LLVM_VER} && \
    ln -s /usr/bin/clang-${LLVM_VER} /usr/bin/clang && \
    ln -s /usr/bin/clang++-${LLVM_VER} /usr/bin/clang++ && \
    ln -s /usr/bin/llvm-rc-${LLVM_VER} /usr/bin/llvm-rc && \
    ln -s /usr/bin/lld-${LLVM_VER} /usr/bin/lld

ENV MANIFEST_DIR=${CI_DIR}/sys_manifests
ENV ARCHIVE_DIR=${CI_DIR}/sys_archives
ENV SDK_ARCHIVE_DIR=${ARCHIVE_DIR}/sdk
ENV MSVC_ARCHIVE_DIR=${ARCHIVE_DIR}/msvc
ENV SYS_DIR=${CI_DIR}/sys

# Prepare SDK and MSVC directories
RUN mkdir -p ${MANIFEST_DIR} && \
    mkdir -p ${SDK_ARCHIVE_DIR} && \
    mkdir -p ${MSVC_ARCHIVE_DIR}

# Download Windows SDK packages
RUN wget -O ${SDK_ARCHIVE_DIR}/winsdk.nupkg https://www.nuget.org/api/v2/package/Microsoft.Windows.SDK.CPP/${SDK_VER} && \
    wget -O ${SDK_ARCHIVE_DIR}/winsdk_x64.nupkg https://www.nuget.org/api/v2/package/Microsoft.Windows.SDK.CPP.x64/${SDK_VER}

# Download MSVC packages
COPY internal/msvcsetup.sh msvcsetup.sh
RUN chmod +x msvcsetup.sh && ./msvcsetup.sh



##################
# LINUX PACKAGES #
##################



RUN apt update && \
    apt-get install -y \
    zlib1g-dev \
    libsdl2-dev\
    libsdl2-image-dev \
    libfreetype6-dev \
    libsndfile1-dev \
    libopenal-dev \
    libalut-dev



######
# CI #
######



RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 30 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 30 && \
    update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30 && \
    update-alternatives --set cc /usr/bin/gcc && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30 && \
    update-alternatives --set c++ /usr/bin/g++ && \
    update-alternatives --config gcc && \
    update-alternatives --config g++

COPY internal/build.sh /ci/build.sh
RUN chmod a+x /ci/build.sh

# Start the application
CMD ["/ci/build.sh"]
