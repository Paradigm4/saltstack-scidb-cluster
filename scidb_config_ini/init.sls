# setup scidb config.ini

{% set VER = pillar['scidb_ver'] %}

scidb_config_ini:
  file.managed:
    - name: {{ '/opt/scidb/'+VER+'/etc/config.ini' }}
    - source: 'salt://scidb_config_ini/config.ini'
    - template: jinja                              # expand the hosts-in-cluster info from pillar
    - makedirs: True

