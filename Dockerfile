FROM ubuntu:18.04 as stage1
MAINTAINER Romel J. Torres <torres.romel@gmail.com>

#install dependences for:
# * downloading Vivado (wget)
# * xsim (gcc build-essential to also get make)
# * MIG tool (libglib2.0-0 libsm6 libxi6 libxrender1 libxrandr2 libfreetype6 libfontconfig)
# * CI (git)
RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  libglib2.0-0 \
  libsm6 \
  libxi6 \
  libxrender1 \
  libxrandr2 \
  libfreetype6 \
  libfontconfig \
  lsb-release

# copy in config file
COPY install_config.txt /tmp/
ADD Xilinx_Vivado_SDK_2019.1_0524_1430.tar.gz /tmp/

RUN /tmp/Xilinx_Vivado_SDK_2019.1_0524_1430/xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install -c /tmp/install_config.txt && \
    rm -rf /tmp/*

FROM ubuntu:16.04

#install dependences for:
# * downloading Vivado (wget)
# * xsim (gcc build-essential to also get make)
# * MIG tool (libglib2.0-0 libsm6 libxi6 libxrender1 libxrandr2 libfreetype6 libfontconfig)
# * CI (git)
RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  libglib2.0-0 \
  libsm6 \
  libxi6 \
  libxrender1 \
  libxrandr2 \
  libfreetype6 \
  libfontconfig \
  lsb-release

# turn off recommends on container OS
# install required dependencies
RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > \
    /etc/apt/apt.conf.d/01norecommend && \
    apt-get update && \
    apt-get -y install \
        bzip2 \
        libc6-i386 \
        git \
        libfontconfig1 \
        libglib2.0-0 \
        sudo \
        nano \
        locales \
        libxext6 \
        libxrender1 \
        libxtst6 \
        libgtk2.0-0 \
        build-essential \
        unzip \
        ruby \
        ruby-dev \
        pkg-config \
        libprotobuf-dev \
        protobuf-compiler \
        python-protobuf \
        python-pip \
	net-tools \
	iputils-ping \
	usbutils \
	isc-dhcp-client && \
        pip install intelhex && \
        echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
        locale-gen && \
        gem install fpm && \
        apt-get clean

COPY --from=stage1 /tools/Xilinx /tools/Xilinx

# add device tree repo (as root)
RUN git clone -b xilinx-v2019.1 --depth 1 https://github.com/Xilinx/device-tree-xlnx.git /tools/Xilinx/Vivado/2019.1/device-tree-xlnx

RUN adduser --disabled-password --gecos '' vivado
USER vivado
WORKDIR /home/vivado

#add vivado tools to path
#copy in the license file
RUN echo "source /tools/Xilinx/Vivado/2019.1/settings64.sh" >> /home/vivado/.bashrc && \
    mkdir /home/vivado/.Xilinx

# customize gui (font scaling 125%)
COPY --chown=vivado:vivado vivado.xml /home/vivado/.Xilinx/Vivado/2019.1/vivado.xml

# set path for DT repo
COPY --chown=vivado:vivado com.xilinx.sdk.sw.prefs /home/vivado/.Xilinx/SDK/2019.1/.settings/com.xilinx.sdk.sw.prefs

# add U96 board files
ADD /board_files.tar.gz /tools/Xilinx/Vivado/2019.1/data/boards/board_files/

# for vivado simulation scripts
RUN pip install lxml