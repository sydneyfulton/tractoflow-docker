# Start from a base image
FROM ubuntu:22.04

# Disable interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Preconfigure keyboard to avoid prompts
RUN apt-get update && \
    echo 'keyboard-configuration keyboard-configuration/layoutcode select us' | debconf-set-selections && \
    echo 'keyboard-configuration keyboard-configuration/modelcode select pc105' | debconf-set-selections

# Set environment variables
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    git \
    bzip2 \
    ca-certificates \
    build-essential \
    openjdk-11-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda (older version to avoid TOS issue)
RUN curl -sSL https://repo.anaconda.com/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh

# Create Conda environment, install Nextflow
RUN conda create -y -n tractoflow python=3.9 && \
    /opt/conda/envs/tractoflow/bin/pip install --upgrade pip && \
    /opt/conda/bin/conda run -n tractoflow conda install -y -c bioconda nextflow=21.10.6 && \
    ln -s /opt/conda/envs/tractoflow/bin/nextflow /usr/local/bin/nextflow

# Clone TractoFlow
RUN git clone https://github.com/scilus/tractoflow.git


# Set working directory
WORKDIR /tractoflow

# --- Install Go (version ≥ 1.17.5) ---
RUN curl -LO https://go.dev/dl/go1.20.12.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.20.12.linux-amd64.tar.gz && \
    rm go1.20.12.linux-amd64.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    go version

# --- Install Apptainer (Singularity) ---
RUN apt-get update && apt-get install -y \
    build-essential \
    uuid-dev \
    libgpgme-dev \
    squashfs-tools \
    libseccomp-dev \
    pkg-config \
    git \
    cryptsetup \
    libglib2.0-dev \
    libfuse-dev \
    libssl-dev \
    libtool \
    libcap-dev && \
    export PATH=$PATH:/usr/local/go/bin && \
    export VERSION=1.1.8 && \
    curl -LO https://github.com/apptainer/apptainer/releases/download/v${VERSION}/apptainer-${VERSION}.tar.gz && \
    tar -xzf apptainer-${VERSION}.tar.gz && \
    cd apptainer-${VERSION} && \
    ./mconfig --without-suid && \
    make -C builddir && \
    make -C builddir install && \
    cd .. && rm -rf apptainer*
    
RUN apt-get update && apt-get install -y \
    squashfuse \
    fuse2fs \
    && rm -rf /var/lib/apt/lists/*


# Pull Singularity container image
RUN singularity pull --name scilus_1.6.0.sif docker://scilus/scilus:1.6.0

# Add alias to global bashrc
#RUN echo "alias tractoflow='nextflow run /tractoflow/main.nf'" >> /root/.bashlearc


RUN echo '#!/bin/bash\nnextflow run /tractoflow/main.nf "$@"' > /usr/local/bin/tractoflow && \
    chmod +x /usr/local/bin/tractoflow

#ENTRYPOINT ["nextflow", "run", "/tractoflow/main.nf"]


# Default command
CMD ["bash"]
