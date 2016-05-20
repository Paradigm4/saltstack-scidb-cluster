#!/bin/bash
#
{% set KEY = pillar['scidbKEY'] %}
{% set VER = pillar['scidbVER'][KEY] %}

set -x

# DEBUG
WHO=$(whoami)
if [ "$WHO" != "root" ] ; then
    echo "$0: needs to be run as root, so it can become postgres or scidbadmin" >&2
    exit $RESULT
fi

# SCIDB.PY INIT-SYSCAT
{{ 'runuser postgres -c \"/opt/scidb/'+VER+'/bin/scidb.py init-syscat --db-password test_dbpassword test_dbname\"' }}
RESULT=$?
if [ "$RESULT" != "0" ] ; then
    echo "$0: scidb.py init-syscat RESULT=$RESULT" >&2
    exit $RESULT
fi
echo "$0: scidb.py init-syscat succeeded" >&2

#
# make config.ini's "base-path" directory readable by posgres user
#

BASE_PATH=$(cat {{ '//opt/scidb/'+VER+'/etc/config.ini' }} | grep base-path | cut -d = -f 2)
echo "$0: BASE_PATH=$BASE_PATH" >&2

SCIDBADMIN_GROUP=$(id -g scidbadmin )			# numeric
usermod -G ${SCIDBADMIN_GROUP} -a postgres	# put postgres in one of scidbadmin's groups


mkdir -p $BASE_PATH
chown scidbadmin:${SCIDBADMIN_GROUP} $BASE_PATH
chmod g+rx $BASE_PATH
chmod g+rx ~scidbadmin    # TODO: remove assumption that $BASE_PATH is inside ~scidbadmin

# SCIDB.PY INITALL-FORCE (-v can be helpful here for debug)
runuser scidbadmin -c "{{ '/opt/scidb/'+VER+'/bin/scidb.py' }} -v initall-force test_dbname"

RESULT=$?
if [ "$RESULT" != "0" ] ; then
    echo "$0: scidb.py initall-force RESULT=$RESULT" >&2
    exit $RESULT
fi
echo "$0: scidb.py initall-force succeeded" >&2

exit 0
