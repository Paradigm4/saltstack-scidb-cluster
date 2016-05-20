# Completely ignore non-RHEL-like systems at this time

{% set KEY = pillar['scidbKEY'] %}
{% set VER = pillar['scidbVER'][KEY] %}

# convert minion fqdn to scidbNameAddr
{% set clusterName  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']  %}
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber'] %}

# DEBUG TIP: show_full_context()

scidb_service_add:
  cmd.run:
    - user: root
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -m p4_system service_add -u scidbadmin' }}
    - require:
      - pkg: scidb_ee                       # must have scidb and plugins installed
      - cmd: scidb_initall                  # must be initialized before it can start

scidb_service_register:
  cmd.run:
    - user: scidbadmin
{% if serverNumber == 0 %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -m p4_system service_register --all test_dbname /opt/scidb/'+VER + '/etc/config.ini' }}
{% else %}
    - name: '/bin/true'
{% endif %}
    - require:
      - cmd: scidb_service_add

scidb_service_start:
  cmd.run:
    - user: scidbadmin
{% if serverNumber == 0 %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -m p4_system start_server --all test_dbname /opt/scidb/'+VER+'/etc/config.ini' }}
{% else %}
    - name: '/bin/true'
{% endif %}
    - require:
      - cmd: scidb_service_register     

