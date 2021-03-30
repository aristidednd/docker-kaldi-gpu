FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu16.04

ENV LANG C.UTF-8

LABEL maintainer="aristide.mendoo@adncorp.com"
LABEL com.nvidia.volumes.needed="nvidia_driver"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    g++ \
    make \
    automake \
    autoconf \
    bzip2 \
    unzip \
    wget \
    sox \
    libtool \
    git \
    subversion \
    fuse \
    python3 \
    python3-pip \
    zlib1g-dev \
    gfortran \
    libboost-all-dev \
    libfst-tools \
    libsox-fmt-all \
    ca-certificates \
    patch \
    ffmpeg \
    vim && \
    rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV PYTHON_VERSION=3.6

RUN git clone --depth 1 https://github.com/kaldi-asr/kaldi.git /opt/kaldi && \
    cd /opt/kaldi/tools && \
    ./extras/install_mkl.sh && \
    make -j $(nproc) && \
    cd /opt/kaldi/src && \
    ./configure --shared --use-cuda && \
    make depend -j $(nproc) && \
    make -j $(nproc) && \
    find /opt/kaldi  -type f \( -name "*.o" -o -name "*.la" -o -name "*.a" \) -exec rm {} \; && \
    find /opt/intel -type f -name "*.a" -exec rm {} \; && \
    find /opt/intel -type f -regex '.*\(_mc.?\|_mic\|_thread\|_ilp64\)\.so' -exec rm {} \; && \
    rm -rf /opt/kaldi/.git

RUN curl -o ~/miniconda.sh -O  https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh  && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda install conda-build

ENV PATH=$PATH:/opt/conda/bin/
ENV WORK_DIR=/storage
ENV KALDI_DIR=/opt/kaldi
ENV KALDI_SCRIPTS=/opt/kaldi/scripts

RUN rm /bin/sh
RUN ln -s /bin/bash /bin/sh

ENV USER kaldi
# Create Environment
COPY environment.yaml /environment.yaml
RUN conda env create -f environment.yaml
COPY scripts  /notebooks

WORKDIR /notebooks
# Activate Source
CMD source activate kaldi
CMD source ~/.bashrc

RUN chmod -R a+w /notebooks
WORKDIR /notebooks

COPY config.yml /root/.kaldi/config.yml
COPY run.sh /run.sh

CMD ["/run.sh"]