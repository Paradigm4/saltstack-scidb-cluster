#!/bin/bash
#

set -x

# DEBUG
WHO=$(whoami)
if [ "$WHO" != "scidbadmin" ] ; then
    echo "$0: needs to be run as scidbadmin"
    exit $RESULT
fi

#
# hosts are passed in as arguments.
# the script is just to iterate over them
# [if we learn how to do this directly in init.sls, we can eliminate this script]
if [ "$#" -lt "1" ] ; then
    echo "$0: requires a minimum of 1 arg: the hostname of server-0" >&2
    exit 1
fi

HOSTS=$*

#
# capture public keys from various hosts in known_hosts
# (this only prevents future MITM attacks, not those already set up)
# 'true' is just a very quick command to run on the remote
# The ssh command itself which updates known_hosts each time
# The -o StrictHostKeyChecking=no prevents it from checking with the tty as
# to whether its okay.
#
# This does have a narrow exposure for a MITM attack, but only if the host spoofing
# happens when this is running (during setup) not while scidb is running,
# because those ssh's leave strict checking enabled.
#
# With additional effort, we could directly manipulate the known_hosts files and close the
# window of risk entirely
#
ssh -o StrictHostKeyChecking=no localhost true  # not sure what ssh's to localhost
ssh -o StrictHostKeyChecking=no 0.0.0.0   true  # mpich does this (when launching?)
for HOST in $HOSTS ; do
    ssh -o StrictHostKeyChecking=no $HOST true	# a host in the cluster
    RESULT=$?
    if [ "$RESULT" != "0" ] ; then
	echo "$0: could not ssh to $HOST to establish known_hosts" >&2
	exit $RESULT
    fi
    echo "$0: known_hosts okay for $HOST" >&2
done

exit 0
