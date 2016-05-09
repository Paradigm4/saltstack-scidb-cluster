# setup scidb config.ini

include:
  - scidb_ee                                      # scidb packages, in this repo

# TODO: adjust this to be the 'basename' of the hostname
#       if its hard to stop at first number
#       just rename them to be msg_1 etc
#

#
# this rule should be on all hosts
#
scidb_config_ini:
  file.managed:
    - name: '/opt/scidb/15.12/etc/config.ini'
    - source: 'salt://scidb_config_ini/config.ini'
    - template: jinja                              # expand the hosts-in-cluster info from pillar
