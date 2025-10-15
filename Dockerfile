FROM nvidia/cuda:12.2.0-devel-rockylinux9
RUN dnf install 'dnf-command(config-manager)' -y && dnf config-manager --enable crb -y && dnf install epel-release -y 
RUN dnf upgrade -y
RUN dnf install git cmake clang-devel llvm-devel json-devel zeromq-devel zlib-devel root\* python3-pip tbb-devel zip unzip lbzip2 -y
RUN dnf install boost-devel fmt-devel python3-devel catch2-devel range-v3-devel python3-clang -y
RUN pip install wrapt cachetools pydot sympy clang==18.1.8
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

ARG USERNAME=allenuser
RUN useradd -m $USERNAME

USER $USERNAME
