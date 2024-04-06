FROM ubuntu:22.04
MAINTAINER swjung89 <sangwon-jung-work@gmail.com>

ARG DEBIAN_FRONTEND=noninteractive
ARG FFMPEG_LATEST_URL

RUN apt-get update -y && apt-get install -y software-properties-common libxml2-utils wget curl jq git openssl libssl-dev tzdata zlib1g-dev nasm xz-utils 
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1000
RUN mkdir /var/src
WORKDIR /var/src

RUN wget -O ffmpeg-nx.x-latest-linux64-gpl-x.x.tar.xz $FFMPEG_LATEST_URL && tar Jxvf ffmpeg-nx.x-latest-linux64-gpl-x.x.tar.xz && cd ffmpeg-*/bin && cp ./* /usr/local/bin

RUN echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf && ldconfig
ADD rec_radiko2.sh /usr/local/bin/rec_radiko2.sh
RUN chmod +x /usr/local/bin/rec_radiko2.sh
RUN mkdir /var/radiko
WORKDIR /var/radiko
ENTRYPOINT ["/usr/local/bin/rec_radiko2.sh"]
