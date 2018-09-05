FROM ubuntu:18.04

ARG ROOT_VERSION=6.14.04

LABEL maintainer="Clemens Lange <clemens.lange@cern.ch>"

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
ARG VERSION
LABEL   org.label-schema.build-date=$BUILD_DATE \
        org.label-schema.name="CERN ROOT ${ROOT_VERSION} python3 Docker images" \
        org.label-schema.description="Provide compiled ROOT python3 environment." \
        org.label-schema.url="https://github.com/clelange/cern-root-python3-docker-ubuntu/" \
        org.label-schema.vcs-ref=$VCS_REF \
        org.label-schema.vcs-url=$VCS_URL \
        org.label-schema.vendor="CERN" \
        org.label-schema.version=$VERSION \
        org.label-schema.schema-version="1.0"

SHELL ["/bin/bash", "-c"]

# Install dependencies and python
RUN apt-get update && \
    apt-get install -y \
    python3 python3-dev python3-pip curl \
    git dpkg-dev cmake g++ gcc binutils libx11-dev \
    libxpm-dev libxft-dev libxext-dev sudo && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 install --upgrade pip setuptools && \
    # make some useful symlinks that are expected to exist
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    if [[ ! -e /usr/bin/python-config ]]; then ln -sf /usr/bin/python3-config /usr/bin/python-config; fi && \
    if [[ ! -e /usr/bin/pip ]]; then ln -sf /usr/bin/pip3 /usr/bin/pip; fi

# Download and install ROOT
WORKDIR /root
RUN curl -O https://root.cern.ch/download/root_v${ROOT_VERSION}.source.tar.gz && \
    tar xzf root_v${ROOT_VERSION}.source.tar.gz && \
    mkdir /opt/root && \
    cd /opt/root && \
    cmake ${HOME}/root-${ROOT_VERSION}/ -Dall=ON \
    -Dpython3=ON \
    -DPYTHON_EXECUTABLE:FILEPATH="/usr/bin/python3" \
    -DPYTHON_INCLUDE_DIR:PATH="/usr/include/python3.6m" \
    -DPYTHON_INCLUDE_DIR2:PATH="/usr/include/x86_64-linux-gnu/python3.6m" \
    -DPYTHON_LIBRARY:FILEPATH="/usr/lib/x86_64-linux-gnu/libpython3.6m.so" && \
    cmake --build . -- -j2 && \
    rm -r ${HOME}/root-${ROOT_VERSION}/

# Create ROOT user
RUN groupadd -g 1000 rootusr && adduser --disabled-password --gecos "" -u 1000 --gid 1000 rootusr && \
    echo "rootusr ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers

USER    rootusr
WORKDIR /home/rootusr
ENV HOME /home/rootusr
ADD dot-pythonrc.py $HOME/.pythonrc.py
ADD dot-bashrc      $HOME/.bashrc
ADD dot-bashrc      $HOME/.zshrc
ADD entrypoint.sh /opt/root/entrypoint.sh
RUN sudo chmod 755 /opt/root/entrypoint.sh

ENTRYPOINT ["/opt/root/entrypoint.sh"]
CMD     ["/bin/zsh"]
