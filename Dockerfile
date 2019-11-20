# This Dockerfile is used to compile our examples, by just adding some dev
# dependencies.

FROM swift:5.1.2

RUN apt-get update && apt-get install -y zlib1g-dev zip openssl libssl-dev