#!/bin/bash
#

set -x

# DEBUG
WHO=$(whoami)
if [ "$WHO" != "root" ] ; then
    echo "$0: needs to be run as root, so it can become postgres or scidbadmin" >&2
    exit $RESULT
fi

#
# COORD_HOST is passed in as the first argument 
# so that we don't have to change the script
# It can be hostname or IP as far as this script is concerned
# except when we get to using scidb.py --init-all --force, I think it has to be an exact string
# match to pg_hba.conf, which is sometimes set up numerically to allow specifying the network mask with a / in CIDR notation
# otherwise, pg_hba.conf and scidb could use hostnames
#

if [ "$#" -lt "1" ] ; then
    echo "$0: requires 1 arg: the hostname or IP of the coordinator" >&2
    exit 1
fi
COORD_HOST="$1"

# .PGPASS
# password on the command line where anyone can see it? yuk
runuser scidbadmin -c "/opt/scidb/15.12/bin/scidblib/pgpass_updater.py --update -H $COORD_HOST -d test_dbname -u test_dbuser -p test_dbpassword"
RESULT=$?
if [ "$RESULT" != "0" ] ; then
    echo "$0: pgpass_updater.py --update RESULT=$RESULT" >&2
    exit $RESULT
fi
echo "$0: pgpass_updater.py --update succeeded" >&2

exit 0
