#!/bin/bash
# 2020.12.07 change auth urls, recording method(swf -> m3u8, wget -> curl)

pid=$$
filedate=`date '+%Y%m%d'`
tempfiledate=`date '+%Y%m%d_%H%M%S'`


outdir="."


#
# Logout Function
#
Logout () {
  curl -H "Accept-Language: ja-jp" \
       -H "Accept-Encoding: gzip, deflate" \
       -H "X-Requested-With: XMLHttpRequest" \
       -b $cookiefile \
       https://radiko.jp/ap/member/webapi/member/logout

    if [ -f $cookiefile ]; then
        rm -f $cookiefile
    fi
    echo "=== Logout: radiko.jp ==="
}


if [ $# -le 3 ]; then
  echo "usage : $0 channel_name duration(minuites) mail password [outputdir] [prefix]"
  exit 1
fi

if [ $# -ge 4 ]; then
  channel=$1
  DURATION=`expr $2 \* 60`
  mail=$3
  pass=$4
fi

if [ $# -ge 5 ]; then
  outdir=$5
fi
PREFIX=${channel}
if [ $# -ge 6 ]; then
  PREFIX=$6
fi


#loginfile="${outdir}/${PREFIX}_${tempfiledate}_login.txt"
cookiefile="${outdir}/${PREFIX}_${tempfiledate}_cookie.txt"
keyfile="${outdir}/${PREFIX}_${tempfiledate}_authkey.txt"
checkfile="${outdir}/${PREFIX}_${tempfiledate}_check.txt"
auth1header="${outdir}/${PREFIX}_${tempfiledate}_auth1Header.txt"
auth2file="${outdir}/${PREFIX}_${tempfiledate}_auth2.txt"
logoutfile="${outdir}/${PREFIX}_${tempfiledate}_logout.txt"




###
# radiko premium, generate cookie
###
if [ $mail ]; then
  curl -X POST -d "mail=$mail&pass=$pass" \
       -c $cookiefile \
       https://radiko.jp/ap/member/login/login

  if [ ! -f $cookiefile ]; then
    echo "failed login"
    exit 1
  fi
fi

###
# check login status
###
curl -H "Accept-Encoding: gzip, deflate" \
     -H "Accept-Language: ja-JP" \
     -H "Cache-Control: no-cache" \
     -b $cookiefile \
     -o $checkfile \
     https://radiko.jp/ap/member/webapi/member/login/check

if [ $? -ne 0 ]; then
  echo "failed login"
  exit 1
fi


# make keyfile
echo 'bcd151073c03b352e1ef2fd66c32209da9ca0afa' > $keyfile


###
# access auth1
###
curl -H "pragma: no-cache" \
     -H "X-Radiko-App: pc_html5" \
     -H "X-Radiko-App-Version: 0.0.1" \
     -H "X-Radiko-User: dummy_user" \
     -H "X-Radiko-Device: pc" \
     -b $cookiefile \
     -D $auth1header \
     https://radiko.jp/v2/api/auth1

if [ $? -ne 0 ]; then
  echo "failed auth1 process"
  Logout
  exit 1
fi

###
# get partial key
###
authtoken=`perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)' ${auth1header}`
offset=`perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)' ${auth1header}`
length=`perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)' ${auth1header}`

partialkey=`dd if=$keyfile bs=1 skip=${offset} count=${length} 2> /dev/null | base64`

echo -e "authtoken: ${authtoken} \n offset: ${offset} length: ${length} \n partialkey: $partialkey"



#
# access auth2
#
curl -H "X-Radiko-User: dummy_user" \
     -H "X-Radiko-Device: pc" \
     -H "X-Radiko-Authtoken: ${authtoken}" \
     -H "X-Radiko-Partialkey: ${partialkey}" \
     -b $cookiefile \
     -o $auth2file \
     https://radiko.jp/v2/api/auth2

if [ $? -ne 0 -o ! -f $auth2file ]; then
  echo "failed auth2 process"
  Logout
  exit 1
fi

echo "authentication success"


areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' ${auth2file}`
echo "areaid: $areaid"


###
# get hls stream url
###
stationinfo="${outdir}/${PREFIX}_${tempfiledate}_${channel}.xml"

if [ -f $stationinfo ]; then
  rm -f $stationinfo
fi

wget -q -O $stationinfo "https://radiko.jp/v3/station/stream/pc_html5/${channel}.xml"

# first areafree url
stream_url=`xmllint --xpath '//url[@timefree='0'][@areafree='1'][1]/playlist_create_url/text()' ${stationinfo}`

# generate random id
lsid=`date +%s999 -d '999999 seconds' | tr -d '\n' | md5sum | cut -d ' ' -f 1`

# add m3u8 parameters
stream_param="?station_id=${channel}&l=15&lsid=${lsid}&type=b"


# start recording & convert aac
ffmpeg -headers "X-Radiko-AreaId: ${areaid}" -headers "X-Radiko-AuthToken: ${authtoken}" -loglevel info -y \
       -i "${stream_url}${stream_param}" -acodec aac -ab 100k -t $DURATION "${outdir}/${PREFIX}_${filedate}.m4a"


# delete temp files
if [ $? = 0 ]; then
  rm -f $keyfile $checkfile $auth1header $auth2file $stationinfo
fi

#
# Logout
#
Logout

