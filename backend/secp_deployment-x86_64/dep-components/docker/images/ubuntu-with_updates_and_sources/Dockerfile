# License: GNU AGPL v3.0
# Author: HITwh Vegetable Group :: ArHShRn

FROM hitwhvg/ubuntu:16.04
LABEL maintainer="HITwh Vegetable Group <https://github.com/hitwh-vegetable-group>"

# Change apt source
RUN apt update && \
    apt install -y apt-utils && \
    apt upgrade -y && \
    apt install -y apt-transport-https

RUN rm -f /etc/apt/sources.list
COPY sources.list /etc/apt
RUN apt update