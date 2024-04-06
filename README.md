# docker-radiko-recorder

Docker 환경에 Radiko 녹음 서버를 구성합니다.

*(서버는 일본지역 내에 있어야 하며, IP 인식지역 이외 방송 녹음을 위해서는 프리미엄 등록이 필요합니다)*

```sh
# save repository
git clone https://github.com/sangwon-jung-work/docker-radiko-recorder.git
cd docker-radiko-recorder

#
# install github cli or latest ffmpeg build url
#
# install github cli
# https://github.com/cli/cli#installation
#
# get url from release page
# search to ffmpeg-nx.x-latest-linux64-gpl-x.x.tar.xz (not master-latest) and copy url that
# https://github.com/yt-dlp/FFmpeg-Builds/releases/tag/latest

#
# set environment variable (for url)
#
# if install github cli
gh auth login

FFMPEG_URL=$( gh api --jq '.assets[8]."browser_download_url"' -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /repos/yt-dlp/FFmpeg-Builds/releases/latest )

#
# if just copy url
FFMPEG_URL=(paste that url)

# Build radiko Recording Server
docker build --build-arg FFMPEG_LATEST_URL=$FFMPEG_URL --tag (image name):(image version) .

# Build radiko Recording Server Example
docker build --build-arg FFMPEG_LATEST_URL=$FFMPEG_URL --tag radiko_recorder:1.1 .

# recording example
docker run --rm -v (save dir):/var/radiko (image name):(image version) FMJ 60 $RADIKO_LOGIN $RADIKO_PASSWORD

# recording example(joqr)
docker run --rm -v /recorder:/var/radiko radiko_recorder:1.1 QRR 31 $RADIKO_LOGIN $RADIKO_PASSWORD
```

Refs
----

- [install github cli for linux](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
- [yt-dlp FFmpeg pre Build repository](https://github.com/yt-dlp/FFmpeg-Builds/releases/tag/latest)
- [コマンドラインでRadikoを録音しよう - Web Design Inspiration](http://blog.kmusiclife.com/p/rec_radiko/)
- [簡易 radiko.jp プレミアム対応 Radiko 録音スクリプト rec_radiko2.sh 公開。 - KOYAMA Yoshiaki のブログ](http://kyoshiaki.hatenablog.com/entry/2014/05/04/184748)
- [radiko 参加放送局一覧](http://www.dcc-jpl.com/foltia/wiki/radikomemo)
