# Completely ignore non-RHEL-like systems at this time

{% set VER = pillar['scidb_ver'] %}

# convert minion fqdn to scidbNameAddr
{% set clusterName  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']  %}
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber'] %}

# DEBUG TIP: show_full_context()

{% if grains.osfinger == "CentOS Linux-7" %}
# HACK ALERT
# copy p4_system.py to /opt/scidb/16.6/bin and remove the p4_system.pyc there
#
scidb_service_p4_system_pyc_remove:
  file.absent:
    - name: /opt/scidb/16.6/bin/p4_system.pyc

scidb_service_p4_system_hack:
  file.managed:
    - name: /opt/scidb/16.6/bin/p4_system.py
    - source: salt://scidb_service/p4_system.py
{% endif %}

scidb_service_add:
  cmd.run:
    - user: root
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -m p4_system service_add -u scidbadmin' }}

{% if serverNumber == 0 %}

scidb_service_stop:
  cmd.run:
    - user: scidbadmin
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system stop_server --all test_dbname /opt/scidb/'+VER+'/etc/config.ini' }}
    - require:
      - cmd: scidb_service_add

scidb_service_unregister:
  cmd.run:
    - user: scidbadmin
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system stop_server --all test_dbname /opt/scidb/'+VER+'/etc/config.ini' }}
    - require:
      - cmd: scidb_service_stop

{% if grains.osfinger != "CentOS Linux-7" %}  # not implemented for systemd
scidb_service_register:
  cmd.run:
    - user: scidbadmin
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system service_register --all test_dbname /opt/scidb/'+VER + '/etc/config.ini' }}
    - require:
      - cmd: scidb_service_unregister

scidb_service_start:
  cmd.run:
    - user: scidbadmin
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system start_server --all test_dbname /opt/scidb/'+VER+'/etc/config.ini' }}
    - require:
      - cmd: scidb_service_register     
{% endif %}

{% endif %}

