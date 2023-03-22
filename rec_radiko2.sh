#!/bin/bash
# 2020.12.07 change auth urls, recording method(swf -> m3u8, wget -> curl)
# 2021.01.02 add FFREPORT (output log information variable)
# 2022.10.04 modify API change(check)
# 2023.03.22 modify login url, using the v2 api, add fail handing and header in check, auth1, auth2
#


pid=$$
filedate=`date '+%Y%m%d'`
tempfiledate=`date '+%Y%m%d_%H%M%S'`
radikorootrul="https://radiko.jp"


outdir="."


#
# Logout Function
#
Logout () {
  curl -H "Accept-Language: ja-jp" \
       -H "Accept-Encoding: gzip, deflate" \
       -H "X-Requested-With: XMLHttpRequest" \
       -b $cookiefile \
       $radikorootrul/ap/member/webapi/member/logout

    #if [ -f $cookiefile ]; then
    #    rm -f $cookiefile
    #fi
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
cookiefile="${outdir}/${PREFIX}_${tempfiledate}_1cookie.txt"
checkfile="${outdir}/${PREFIX}_${tempfiledate}_2check.txt"
keyfile="${outdir}/${PREFIX}_${tempfiledate}_3authkey.txt"
auth1header="${outdir}/${PREFIX}_${tempfiledate}_4auth1Header.txt"
auth2file="${outdir}/${PREFIX}_${tempfiledate}_5auth2.txt"
#logoutfile="${outdir}/${PREFIX}_${tempfiledate}_logout.txt"




###
# radiko premium, generate cookie
###
if [ $mail ]; then
  curl -X POST -d "mail=$mail&pass=$pass" \
       -c $cookiefile \
       $radikorootrul/ap/member/webapi/member/login

  if [ ! -f $cookiefile ]; then
    echo "failed login"
    exit 1
  fi
fi

###
# check login status
###
curl -H "pragma: no-cache" \
     -H "X-Radiko-App: pc_html5" \
     -H "X-Radiko-App-Version: 0.0.1" \
     -H "X-Radiko-User: dummy_user" \
     -H "X-Radiko-Device: pc" \
     -b $cookiefile \
     -o $checkfile \
     $radikorootrul/ap/member/webapi/member/login/check

if [ $? -eq 0 ] && [ -s $checkfile ];
then
  
  getstatus=`cat ${checkfile} | jq -r '.status'`
  
  if [ $getstatus -eq 200 ]
  then
    echo "login status check success"
  
  else
    echo "login status not 200. ${getstatus}"
    Logout
    exit 1
    
    # getstatus if end
  fi
  
else
  echo "login status check fail"
  Logout
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
     $radikorootrul/v2/api/auth1

if [ $? -eq 0 ] && [ -s $auth1header ];
then
  
  if [ "$(grep -c "200 OK" "$auth1header" )" -eq 1 ];
  then
    echo "auth1 request success"
  
  else
    echo "auth1 response not 200"
    Logout
    exit 1
    
    # auth1 header text check if end
  fi
  
else
  echo "auth1 request fail"
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
curl -H "pragma: no-cache" \
     -H "X-Radiko-App: pc_html5" \
     -H "X-Radiko-App-Version: 0.0.1" \
     -H "X-Radiko-User: dummy_user" \
     -H "X-Radiko-Device: pc" \
     -H "X-Radiko-Authtoken: ${authtoken}" \
     -H "X-Radiko-Partialkey: ${partialkey}" \
     -b $cookiefile \
     -o $auth2file \
     $radikorootrul/v2/api/auth2

if [ $? -ne 0 -o ! -f $auth2file ]; then
  echo "failed auth2 process"
  Logout
  exit 1
fi

if [ $? -eq 0 ] && [ -s $auth2file ];
then
  
  if [ "$(grep -c "JP13" "$auth2file" )" -eq 1 ];
  then
    echo "auth2 request success"
  
  else
    echo "auth2 response not normal"
    Logout
    exit 1
    
    # auth2 header text check if end
  fi
  
  
else
  echo "auth2 request fail"
  Logout
  exit 1
  
fi


echo "authentication success"


areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' ${auth2file}`
echo "areaid: $areaid"


###
# get station's areafree information
###
fullstation="${outdir}/${PREFIX}_${tempfiledate}_full.xml"

if [ -f $fullstation ]; then
  rm -f $fullstation
fi

wget -q -O $fullstation "${radikorootrul}/v3/station/region/full.xml"

echo "${radikorootrul}/v3/station/region/full.xml"

stAreafree=`xmllint --xpath "//station[id[text()='${channel}']]/areafree/text()" ${fullstation}`

# detect areafree, type code
if [ $stAreafree -eq 1 ]; then
  areafree=1
  connectiontype='c'
else
  areafree=0
  connectiontype='b'
fi


###
# get station's hls stream url
###
stationinfo="${outdir}/${PREFIX}_${tempfiledate}_${channel}.xml"

if [ -f $stationinfo ]; then
  rm -f $stationinfo
fi

wget -q -O $stationinfo "${radikorootrul}/v3/station/stream/pc_html5/${channel}.xml"

echo "${radikorootrul}/v3/station/stream/pc_html5/${channel}.xml"

# first areafree url
stream_url=`xmllint --xpath '//url[@timefree='0'][@areafree='${areafree}'][1]/playlist_create_url/text()' ${stationinfo}`

# generate random id
lsid=`date +%s999 -d '999999 seconds' | tr -d '\n' | md5sum | cut -d ' ' -f 1`


# add m3u8 parameters
stream_param="?station_id=${channel}&l=15&lsid=${lsid}&type=${connectiontype}"


# check exist log folder
if [ ! -d $outdir/log ];
then
  mkdir $outdir/log
fi

# set ffmpeg log variable(output file info, set log level debug
export FFREPORT=file=$outdir/log/radiko_$PREFIX.log.$filedate:level=48


# start recording & convert aac
ffmpeg -headers "X-Radiko-AreaId: ${areaid}" -headers "X-Radiko-AuthToken: ${authtoken}" -loglevel info -y \
       -i "${stream_url}${stream_param}" -acodec copy -t $DURATION "${outdir}/${PREFIX}_${filedate}.m4a"


# delete temp files
if [ $? = 0 ]; then
  
  #
  # Logout
  #
  Logout
  
  rm -f $keyfile $checkfile $auth1header $auth2file $fullstation $stationinfo
else
  
  #
  # Logout
  #
  Logout
  
  rm -f $keyfile $checkfile $auth1header $auth2file $fullstation $stationinfo
fi

