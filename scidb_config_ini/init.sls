# setup scidb config.ini

{% set VER = pillar['scidb_ver'] %}

# config.ini source is now per-cluster
#            however all have to share the same mechanism
#            for setting up the data directories so that part
#            only varies by certain parameterizations until
#            that setup is separately factored

scidb_config_ini:
  file.managed:
    - name: {{ '/opt/scidb/'+VER+'/etc/config.ini' }}
    - source: 'salt://scidb_config_ini/config.ini'
    - template: jinja                              # expand the hosts-in-cluster info from pillar
    - makedirs: True


