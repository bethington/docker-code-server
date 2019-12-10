# docker build -t bethington/code-server:latest .
FROM ubuntu:18.04

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="xebyte.com version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="bethington"

# environment settings
ENV HOME="/home/coder"

RUN \
 apt-get update && \
 apt-get install -y \
	git \
	locales \
	nano \
	net-tools \
	sudo \
	dumb-init \
	curl \
	wget \
	apt-transport-https \
	ca-certificates \
        software-properties-common && \
 echo "**** install code-server ****" && \
 if [ -z ${CODE_RELEASE+x} ]; then \
	CODE_RELEASE=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -o \
 /tmp/code.tar.gz -L \
	"https://github.com/cdr/code-server/releases/download/${CODE_RELEASE}/code-server${CODE_RELEASE}-linux-x86_64.tar.gz" && \
 tar xzf /tmp/code.tar.gz -C \
	/usr/bin/ --strip-components=1 \
  --wildcards code-server*/code-server && \
 echo "**** clean up ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*
	
RUN locale-gen en_US.UTF-8
# We cannot use update-locale because docker will not use the env variables
# configured in /etc/default/locale so we need to set it manually.
ENV LC_ALL=en_US.UTF-8 \
	SHELL=/bin/bash

RUN adduser --gecos '' --disabled-password coder && \
	echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
	
RUN mkdir -p /home/coder/{.code-server,.code-server/extensions,.code-server/data,.local,.local/code-server,.ssh} && \
        # permissions
	chown -R coder:coder /home/coder
	
USER coder

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
 add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
 apt-get update && \
 apt-get install -y docker-ce-cli && \
 usermod -aG docker coder

WORKDIR /home/coder

VOLUME /home/coder

# ports and volumes
EXPOSE 8080

ENTRYPOINT dumb-init code-server --host 0.0.0.0 \
				 --port 8080 \
				 --user-data-dir /home/coder/.code-server/data \
				 --extensions-dir /home/coder/.code-server/extensions \
				 --disable-telemetry \
				 --disable-updates \
				 --auth "password" \
				 /home/coder
