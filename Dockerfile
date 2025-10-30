FROM nvidia/cuda:12.6.0-devel-rockylinux9

RUN dnf install 'dnf-command(config-manager)' -y \
 && dnf config-manager --enable crb -y \
 && dnf install epel-release -y

RUN dnf upgrade -y

RUN dnf install git cmake clang-devel llvm-devel json-devel zeromq-devel zlib-devel python3-pip tbb-devel zip unzip lbzip2 cpio -y
RUN dnf install boost-devel fmt-devel python3-devel catch2-devel range-v3-devel python3-clang -y

# Modern GCC/libstdc++ compatible with CUDA 12.6 (Allen GPU build requirement)
RUN dnf install gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-libstdc++-devel gcc-toolset-13-runtime -y

ENV GCC_TOOLSET_ROOT=/opt/rh/gcc-toolset-13/root
ENV PATH="${GCC_TOOLSET_ROOT}/usr/bin:${PATH}"
ENV LD_LIBRARY_PATH="${GCC_TOOLSET_ROOT}/usr/lib64:${LD_LIBRARY_PATH}"
ENV LIBRARY_PATH="${GCC_TOOLSET_ROOT}/usr/lib64:${LIBRARY_PATH}"
ENV CPATH="${GCC_TOOLSET_ROOT}/usr/include:${CPATH}"
ENV CC="${GCC_TOOLSET_ROOT}/usr/bin/gcc"
ENV CXX="${GCC_TOOLSET_ROOT}/usr/bin/g++"

RUN pip install wrapt cachetools pydot sympy clang==18.1.8 pyeda
RUN ln -s /usr/bin/python3.9 /usr/bin/python

RUN mkdir deps
WORKDIR /deps

RUN git clone https://github.com/edanor/umesimd.git 
ENV UMESIMD_ROOT_DIR=/deps/

RUN git clone https://github.com/microsoft/GSL.git &&\
    cd GSL &&\
    git checkout v3.1.0 &&\
    mkdir build && cd build &&\
    cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_GMOCK=OFF -DGSL_TEST=OFF -DINSTALL_GTEST=OFF .. &&\
    make -j && make install

RUN dnf install ninja-build bash-completion -y

# Install ROOT build dependencies
RUN dnf -y update \
    && dnf -y install dnf-plugins-core \
    && dnf -y install epel-release \
    && dnf config-manager --set-enabled crb \
    && dnf -y install \
       git cmake make gcc gcc-c++ gcc-gfortran \
       pcre-devel mesa-libGL-devel mesa-libGLU-devel \
       glew-devel ftgl-devel mysql-devel fftw-devel cfitsio-devel \
       graphviz-devel libuuid-devel avahi-compat-libdns_sd-devel \
       openldap-devel python3 python3-devel python3-numpy libxml2-devel \
       libX11-devel libXpm-devel libXft-devel libXext-devel \
       gsl-devel readline-devel qt5-qtwebengine-devel \
       R-devel R-Rcpp-devel R-RInside-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Fetch ROOT sources
RUN git clone --branch latest-stable --depth=1 https://github.com/root-project/root.git root_src

# Build and install ROOT
RUN cmake -S root_src -B root_build \
        -DCMAKE_INSTALL_PREFIX=/deps/root_install \
        -DCMAKE_CXX_STANDARD=20 \
    && cmake --build root_build --target install -j"$(nproc)"

ENV ROOTSYS=/deps/root_install
ENV PATH="${ROOTSYS}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${ROOTSYS}/lib:${LD_LIBRARY_PATH}"
ENV PYTHONPATH="${ROOTSYS}/lib:${PYTHONPATH}"

ARG USERNAME=allenuser
RUN useradd -m $USERNAME

USER $USERNAME
