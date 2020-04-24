# syntax = docker/dockerfile:experimental
#--------------------------------------------------------------
# build image
#--------------------------------------------------------------
ARG GOLANG_VERSION=1.14.2-alpine
FROM golang:${GOLANG_VERSION}

#--------------------------------------------------------------
# ARG
#--------------------------------------------------------------
ARG CLOUD_COMMANDS_VERSION=0.2.5

#--------------------------------------------------------------
# ENV
#--------------------------------------------------------------
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

#--------------------------------------------------------------
# Install dependent packages
#--------------------------------------------------------------
RUN apk add --no-cache make git zip bash openssh curl gcc sudo python && \
    # fix sudo: setrlimit(RLIMIT_CORE): Operation not permitted
    echo "Set disable_coredump false" >> /etc/sudo.conf && \
    # setting commands
    git clone --depth 1 -b v${CLOUD_COMMANDS_VERSION} https://github.com/y-miyazaki/cloud-commands.git && \
    cloud-commands/install.sh && \
    rm -rf cloud-command