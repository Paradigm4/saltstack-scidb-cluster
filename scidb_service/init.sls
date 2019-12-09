# Completely ignore non-RHEL-like systems at this time

{% from 'idioms.sls' import VER %}
{% from 'idioms.sls' import CLUSTER_NAME, INST_GROUP %}

# convert minion fqdn to scidbNameAddr
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber'] %}

# DEBUG TIP: show_full_context()

# HACK ALERT
# copy p4_system.py to /opt/scidb/16.6/bin and remove the p4_system.pyc there
#
# The pyc file was compiled on CentOS 6 with python 2.6 and would not run on CentOS 7 which had python 2.7
# Before and after 16.6 no pyc files were shipped, only the py files.
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
#
# In the middle of the 18.2 runs the use of scidb.py was deprecated in favor of scidbctl.py
# The runs of 18.2 that had scidbctl.py are listed with an install_group of 18.2RCscidbctl
#
# So use scidbctl.py if release > 18.2 or if the install_group of an 18.2 package repo is "18.2RCscidbctl"
#
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py enable-service --user scidbadmin' }}
{% elif INST_GROUP == "18.2RCscidbctl" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py enable-service --user scidbadmin' }}
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -m p4_system service_add -u scidbadmin' }}
{% endif %}

{% if serverNumber == 0 %}

scidb_service_stop:
  cmd.run:
    - user: scidbadmin
#
# In the middle of the 18.2 runs the use of scidb.py was deprecated in favor of scidbctl.py
# The runs of 18.2 that had scidbctl.py are listed with an install_group of 18.2RCscidbctl
#
# So use scidbctl.py if release > 18.2 or if the install_group of an 18.2 package repo is "18.2RCscidbctl"
#
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini stop test_dbname' }}
{% elif INST_GROUP == "18.2RCscidbctl" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini stop test_dbname' }}
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system stop_server --all test_dbname /opt/scidb/'+VER+'/etc/config.ini' }}
{% endif %}
    - require:
      - cmd: scidb_service_add

scidb_service_unregister:
  cmd.run:
    - user: scidbadmin
#
# In the middle of the 18.2 runs the use of scidb.py was deprecated in favor of scidbctl.py
# The runs of 18.2 that had scidbctl.py are listed with an install_group of 18.2RCscidbctl
#
# So use scidbctl.py if release > 18.2 or if the install_group of an 18.2 package repo is "18.2RCscidbctl"
#
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini unregister-service test_dbname' }}
{% elif INST_GROUP == "18.2RCscidbctl" %}
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
#
# In the middle of the 18.2 runs the use of scidb.py was deprecated in favor of scidbctl.py
# The runs of 18.2 that had scidbctl.py are listed with an install_group of 18.2RCscidbctl
#
# So use scidbctl.py if release > 18.2 or if the install_group of an 18.2 package repo is "18.2RCscidbctl"
#
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini register-service test_dbname'}}
{% elif INST_GROUP == "18.2RCscidbctl" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini register-service test_dbname'}}
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system service_register --all test_dbname /opt/scidb/'+VER + '/etc/config.ini' }}
{% endif %}
    - require:
      - cmd: scidb_service_unregister

scidb_service_start:
  cmd.run:
    - user: scidbadmin
#
# In the middle of the 18.2 runs the use of scidb.py was deprecated in favor of scidbctl.py
# The runs of 18.2 that had scidbctl.py are listed with an install_group of 18.2RCscidbctl
#
# So use scidbctl.py if release > 18.2 or if the install_group of an 18.2 package repo is "18.2RCscidbctl"
#
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini start test_dbname' }}
{% elif INST_GROUP == "18.2RCscidbctl" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py --config /opt/scidb/'+VER+'/etc/config.ini start test_dbname' }}
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py -v -m p4_system start_server --all test_dbname /opt/scidb/'+VER+'/etc/config.ini' }}
{% endif %}
    - require:
      - cmd: scidb_service_register     
{% endif %}

{% endif %}

