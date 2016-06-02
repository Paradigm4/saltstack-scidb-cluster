#!/bin/bash
#
{% set VER = pillar['scidb_ver'] %}

set -x


#
# make config.ini's "base-path" directory readable by posgres user
#

BASE_PATH=$(cat {{ '//opt/scidb/'+VER+'/etc/config.ini' }} | grep base-path | cut -d = -f 2)
echo "$0: BASE_PATH=$BASE_PATH" >&2

SCIDBADMIN_GROUP=$(id -g scidbadmin )			# numeric
usermod -G ${SCIDBADMIN_GROUP} -a postgres	# put postgres in one of scidbadmin's groups

rm -r $BASE_PATH

mkdir -p $BASE_PATH
chown scidbadmin:${SCIDBADMIN_GROUP} $BASE_PATH
chmod g+rx $BASE_PATH
chmod g+rx ~scidbadmin    # TODO: remove assumption that $BASE_PATH is inside ~scidbadmin

