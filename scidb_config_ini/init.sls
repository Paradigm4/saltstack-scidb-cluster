# setup scidb config.ini

{% set KEY = pillar['scidbKEY'] %}
{% set VER = pillar['scidbVER'][KEY] %}


# TODO: adjust this to be the 'basename' of the hostname
#       if its hard to stop at first number
#       just rename them to be msg_1 etc
#

#
# this rule should be on all hosts
#
scidb_config_ini:
  file.managed:
    - name: {{ '/opt/scidb/'+VER+'/etc/config.ini' }}
    - source: 'salt://scidb_config_ini/config.ini'
    - template: jinja                              # expand the hosts-in-cluster info from pillar
