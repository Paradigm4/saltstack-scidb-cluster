include:
  - postgres               # https://github.com/saltstack-formulas/postgres-formulas

#
# 4 steps according to scidb install instructions
# all on head server at this time
#
# 1. have pg_hba.conf created by doing "service postgresql initdb"
# 2. modify pg_hba.conf to allow remote access
# 3. modify postgresql.conf to allow other connections
# 4. restart posgresql
# 5. change service config so that it starts whenever linux comes up
#
#- file: # 3. postgresql.conf modified for multiple connections
#- xxx: posgres service set to start at boot

# find cluster and server from administrative name (same as minion is addressed)
{% set clusterName  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']  %}
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']  %}
{% set listenerCIDR = pillar['scidb_cluster_info'][clusterName]['postgresListenerCIDR']  %}



# todo: can the above use ... pillar.scidb_minion_info as in YAML ?
# DEBUG TIP show_full_context()

{% if serverNumber == 0 %}

postgres_scidb_config_hba_conf:
  file.replace:
  - name: /var/lib/pgsql/data/pg_hba.conf     # TODO: use postgres.conf_dir (see  pg_hba.conf formula)
  - append_if_not_found: True
  - pattern: "host all all * md5"               # should not be there anyway ... really this is an "append"
# TODO: this is the only way this can work for PG 8.3
  - repl: {{ 'host all all ' + listenerCIDR + ' md5' }}
  - require:
    - file: pg_hba.conf
# TODO: for PG 9.3 something like this might allow using the scidbNameAddr + mask 
#       or listing all the hosts in the cluster explicitly
# would need a jinja loop
# {# - repl: {{ 'host all all ' + scidbNameAddr  + ' md5' }} #} # TODO: parameterize subnet/mask per cluster

# TODO: learn how to extend the formulas states, may eliminate a second postgres restart
#       after overwriting hba.conf

#
# NOTE:
#    pillar postgres.postgresconf must be set in e.g. /srv/pillar/data.sls to
#    "listener_address = '*' \n port = 5432"
#

# todo: cmd.run -> service.running (see p4_pxeboot)
postgres_scidb_config_restart:
  cmd.run:
  - cwd: /
  - user: root
  - name: service postgresql restart
  - require:
    - service: run-postgresql

{% else %}  # just define an empty postgres_scidb_config_restart

postgres_scidb_config_restart:
  cmd.run:
  - name: /bin/true

{% endif %}
