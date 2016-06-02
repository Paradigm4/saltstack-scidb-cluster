#    TODO: can the actions of do_inits.sh be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

{% set VER = pillar['scidb_ver'] %}

{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']  %}


{% if (serverNumber == 0 ) %}

scidb_init_syscat:
  cmd.run:
    - name: runuser postgres -c "{{ '/opt/scidb/'+VER+'/bin/scidb.py' }}  -v init-syscat --db-password test_dbpassword test_dbname"

scidb_initall:
  cmd.run:
    - name: runuser scidbadmin -c "{{ '/opt/scidb/'+VER+'/bin/scidb.py' }} -v initall-force test_dbname"

{% endif %}

