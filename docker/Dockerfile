# This Dockerfile is used to compile our examples, by just adding some dev
# dependencies.
ARG SWIFT_VERSION=5.0
FROM fabianfett/amazonlinux-swift:$SWIFT_VERSION-amazonlinux2

# needed to do again after FROM due to docker limitation
ARG SWIFT_VERSION

RUN yum -y update && \
  yum -y install zlib-devel kernel-devel gcc-c++ openssl-devel