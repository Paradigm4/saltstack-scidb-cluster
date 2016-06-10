#    TODO: can the actions of do_inits.sh be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

{% set VER = pillar['scidb_ver'] %}

# which host the posgres is running on
{% set CLUSTER_NAME  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']  %}
{% set PSQL_NAME_ADDR = pillar['scidb_cluster_info'][CLUSTER_NAME]['hosts'][0]['scidbNameAddr'] %}

# which index in cluster this server is
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']  %}


{% if (serverNumber == 0 ) %}
scidb_init_syscat:
  cmd.run:
    - name: runuser postgres -c "{{ '/opt/scidb/'+VER+'/bin/scidb.py' }}  -v init-syscat --db-password test_dbpassword test_dbname"
{% endif %}

#
# NOCHECKIN:
# PREREQUISITES of the most common (inscrutable) errors from init-syscat
# 1) that scidb_data_dirs succeeded (not included here because its destructive)

# scidb_init_check_data_dirs_empty:
#   cmd.run:  needs implementation

# 2) that each server can reach the psql server
#    e.g. validate psql config and local .pgpass file
#
scidb_init_psql_check:
  cmd.run:
    - runas: scidbadmin
    - name: psql -U test_dbuser -d test_dbname -h {{ PSQL_NAME_ADDR }} --command="select 'Hello world'"

{% if (serverNumber == 0 ) %}
scidb_initall:
  cmd.run:
    - name: runuser scidbadmin -c "{{ '/opt/scidb/'+VER+'/bin/scidb.py' }} -v initall-force test_dbname"
    - requires: scidb_init_psql_check
{% endif %}

