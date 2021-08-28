FROM ubuntu
MAINTAINER valentin "valentin.rudloff.perso@gmail.con"
COPY . /app


ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt upgrade \
  && apt-get install -y python3-pip python3-dev \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 install --upgrade pip

WORKDIR /dep
RUN apt remove --purge cmake
RUN apt install libssl-dev
RUN wget https://cmake.org/files/v3.20/cmake-3.20.0.tar.gz
RUN tar -xzvf cmake-3.20.0.tar.gz
WORKDIR /dep/cmake-3.20.0
RUN ./bootstrap
RUN make -j4
RUN make install

WORKDIR /dep
RUN git clone https://github.com/KhronosGroup/glslang.git
WORKDIR /dep/glslang
RUN git clone https://github.com/google/googletest.git External/googletest
RUN python update_glslang_sources.py
RUN mkdir build
WORKDIR /dep/build
RUN cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(pwd)/install" ..
RUN make -j4 install

RUN apt-get install libvulkan-dev

WORKDIR /app
RUN git submodule update --init --recursive
RUN sed -i '19s+.*+find_program(GLSLANGVALIDATOR_EXECUTABLE NAMES glslangValidator PATHS /dep/glslang/build/install/bin)+' /app/src/CMakeLists.txt
RUN mkdir build
WORKDIR /app/build
RUN cmake ../src
RUN cmake --build . -j 4