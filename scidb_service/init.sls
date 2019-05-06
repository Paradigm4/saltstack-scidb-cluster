# Completely ignore non-RHEL-like systems at this time

{% from 'idioms.sls' import VER %} {# was: set VER = pillar['scidb_ver'] #}
{% from 'idioms.sls' import CLUSTER_NAME %}

# convert minion fqdn to scidbNameAddr
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber'] %}

# DEBUG TIP: show_full_context()

# HACK ALERT
# copy p4_system.py to /opt/scidb/16.6/bin and remove the p4_system.pyc there
#
{% if grains.osfinger == "CentOS Linux-7" %}
{% if VER == "16.6" %}
scidb_service_p4_system_pyc_remove:
  file.absent:
    - name: /opt/scidb/16.6/bin/p4_system.pyc

scidb_service_p4_system_hack:
  file.managed:
    - name: /opt/scidb/16.6/bin/p4_system.py
    - source: salt://scidb_service/p4_system.py
{% endif %}
{% endif %}

scidb_service_add:
  cmd.run:
    - user: root
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py enable-service --user scidbadmin' }}
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -m p4_system service_add -u scidbadmin' }}
{% endif %}

{% if serverNumber == 0 %}

scidb_service_stop:
  cmd.run:
    - user: scidbadmin
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini stop test_dbname' }}
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system stop_server --all test_dbname /opt/scidb/'+VER+'/etc/config.ini' }}
{% endif %}
    - require:
      - cmd: scidb_service_add

scidb_service_unregister:
  cmd.run:
    - user: scidbadmin
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini unregister-service test_dbname' }}
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system stop_server --all test_dbname /opt/scidb/'+VER+'/etc/config.ini' }}
{% endif %}
    - require:
      - cmd: scidb_service_stop

{% if grains.osfinger != "CentOS Linux-7" %}  {# not implemented for systemd #}
scidb_service_register:
  cmd.run:
    - user: scidbadmin
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini register-service test_dbname'}}
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system service_register --all test_dbname /opt/scidb/'+VER + '/etc/config.ini' }}
{% endif %}
    - require:
      - cmd: scidb_service_unregister

scidb_service_start:
  cmd.run:
    - user: scidbadmin
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini start test_dbname' }}
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system start_server --all test_dbname /opt/scidb/'+VER+'/etc/config.ini' }}
{% endif %}
    - require:
      - cmd: scidb_service_register     
{% endif %}

{% endif %}

