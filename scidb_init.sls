#    TODO: can the actions of do_inits.sh be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

{% from 'idioms.sls' import VER %}
{% from 'idioms.sls' import CLUSTER_NAME, INST_GROUP %}

# which host the posgres is running on
{% set PSQL_NAME_ADDR = pillar['scidb_cluster_info'][CLUSTER_NAME]['hosts'][0]['scidbNameAddr'] %}

# which index in cluster this server is
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']  %}


{% if (serverNumber == 0 ) %}
scidb_init_syscat:
  cmd.run:
    - user: postgres
#
# In the middle of the 18.2 runs the use of scidb.py was deprecated in favor of scidbctl.py
# The runs of 18.2 that had scidbctl.py are listed with an install_group of 18.2RCscidbctl
#
# So use scidbctl.py if release > 18.2 or if the install_group of an 18.2 package repo is "18.2RCscidbctl"
#
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py' }} init-syscat --db-password test_dbpassword test_dbname
{% elif INST_GROUP == "18.2RCscidbctl" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py' }} init-syscat --db-password test_dbpassword test_dbname
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py' }} init-syscat --db-password test_dbpassword test_dbname
{% endif %}
{% endif %}

#
# NOCHECKIN:
# PREREQUISITES of the most common (inscrutable) errors from init-syscat
# 1) that scidb_data_dirs succeeded (not included here because its destructive)

# scidb_init_check_data_dirs_empty:
# TODO >>>  cmd.run:  needs implementation <<<

# 2) that each server can reach the psql server
#    e.g. validate psql config and local .pgpass file
#
#  this is a common failure point. common problems...
#  1) check ~scidbadmin/.pgpass contents
#     if it has multiple hostnames delete the file
#     (maybe the append-anyway option when configuring that file is a bad idea?)
#
scidb_init_psql_check:
  cmd.run:
    # NOTE: link from /usr/bin/psql to /etc/alternatives missing on Centos7 ... so just use the alternative link itself
    # NOTE: this will only work on Centos, may require rework with 'cmd.run - unless:' to also work with ubuntu
    - user: scidbadmin
    - name: psql -U test_dbuser -d test_dbname -h {{ PSQL_NAME_ADDR }} --command="select 'Hello world'"

{% if (serverNumber == 0 ) %}
scidb_initall:
  cmd.run:
    - user: scidbadmin
#
# In the middle of the 18.2 runs the use of scidb.py was deprecated in favor of scidbctl.py
# The runs of 18.2 that had scidbctl.py are listed with an install_group of 18.2RCscidbctl
#
# So use scidbctl.py if release > 18.2 or if the install_group of an 18.2 package repo is "18.2RCscidbctl"
#
{% if VER > "18.2" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py' }} init-cluster --force test_dbname
{% elif INST_GROUP == "18.2RCscidbctl" %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidbctl.py' }} init-cluster --force test_dbname
{% else %}
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py' }} initall-force test_dbname
{% endif %}
    - requires: scidb_init_psql_check
{% endif %}

