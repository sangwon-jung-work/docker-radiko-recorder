#!/bin/sh
# crontab radiko rec shell
# 2020.02.08
# 2020.02.25 Del PREFIX Date
# 2020.05.29 del tee log
#
# 大橋彩香のAnyBeat!
# Sun 21:00
# 59 20 * * 0


# Common
REC_ROOT=/recorder

# Recording Info
STATION=QRR
REC_MIN=31
PREFIX=AYAKA

# Radiko Account Info
R_ID=(ID)
R_PW=(PW)

/usr/bin/docker run --rm -v $REC_ROOT:/var/radiko radiko_recorder:1.1 $STATION $REC_MIN $R_ID $R_PW . $PREFIX
