FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG FFMPEG_LATEST_URL
ARG BUILD_DATE

LABEL recorder.image.authors=sangwon-jung-work@gmail.com
LABEL recorder.image.vendor=swjung
LABEL recorder.image.version=1.10
LABEL recorder.image.target=joqr
LABEL recorder.image.release-date=$BUILD_DATE

RUN apt-get update -y && apt-get install -y software-properties-common libxml2-utils wget curl jq git openssl libssl-dev tzdata zlib1g-dev nasm xz-utils 
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1000
RUN mkdir /var/src
WORKDIR /var/src

RUN wget -O ffmpeg-latest-linux64-gpl.tar.xz $FFMPEG_LATEST_URL && tar Jxvf ffmpeg-latest-linux64-gpl.tar.xz && cd ffmpeg-*/bin && cp ./* /usr/local/bin

RUN echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf && ldconfig
ADD rec_radiko2.sh /usr/local/bin/rec_radiko2.sh
RUN chmod +x /usr/local/bin/rec_radiko2.sh
RUN mkdir /var/radiko
WORKDIR /var/radiko
ENTRYPOINT ["/usr/local/bin/rec_radiko2.sh"]
