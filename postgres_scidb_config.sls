
{% set KEY = pillar['scidbKEY'] %}
#
# 4 steps according to scidb install instructions
# all on head server at this time
#
# 1. have pg_hba.conf created by doing "service postgresql initdb"
# 2. modify pg_hba.conf to allow remote access
# 3. modify postgresql.conf to allow other connections
# 4. restart postgresql
# 5. change service config so that it starts whenever linux comes up
#
#- file: # 3. postgresql.conf modified for multiple connections
#- xxx: postgres service set to start at boot

# find cluster and server from administrative name (same as minion is addressed)
{% set clusterName  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']         %}
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']        %}
{% set PG_LISTEN_CIDR = pillar['scidb_cluster_info'][clusterName]['postgresListenerCIDR']  %}

# todo: can the above use ... pillar.scidb_minion_info as in YAML ?
# DEBUG TIP show_full_context()

# remove prior exiting PG84 or PG 93 data directories

# remove prior/next version of postgres
scidb_postgres_remove:
  pkg.removed:
    - pkgs: {{ pillar['postgres_pkgs_other'] }}
      #- postgresql
      #- postgresql-contrib
      #- postgresql-libs
      #- postgresql-server

# remove prior/next config directory
scidb_postgres_rmdir_other:
  file.absent:
    - name: {{ pillar['postgres_data_dir_other'] }}


scidb_postgres_repo_install:
  pkg.installed:
    - name: {{ pillar['postgres_repo_name'] }}
    - sources: {{ pillar['postgres_repo_sources'] }}

scidb_postgres_install:
  pkg.installed:
    - pkgs: {{ pillar['postgres_pkgs'] }}

# now need a service start and stuff like that

{% if serverNumber == 0 %}

# stop the existing service (may be using wrong config)
postgres_scidb_stopped:
  service.dead:
    - name: {{ pillar['postgres_service'] }}

# remove current config directory (will be replaced by postgres init)
scidb_postgres_rmdir:
  file.absent:
    - name: {{ pillar['postgres_data_dir'] }}

postgres_scidb_init:
  cmd.run:
{% if grains['init'] == "systemd" %}
    - name: /usr/pgsql-9.3/bin/postgresql93-setup initdb
{% else %}
    - name: service {{pillar['postgres_service']}} initdb
{% endif %}

postgres_scidb_config_hba_conf:
  file.replace:
  - name: {{ pillar['postgres_data_dir']+'/pg_hba.conf' }}
  - append_if_not_found: True
  - pattern: 'host all all [^ ]* md5'               # should not be there anyway ... really this is an "append"
  - repl: {{ 'host all all ' + PG_LISTEN_CIDR + ' md5' }}

# TODO: the above is the only way this can work for PG 8.3
# TODO: but for PG 9.3 something like this might allow using the scidbNameAddr + mask 
#       or listing all the hosts in the cluster explicitly
# would need a jinja loop
# {# - repl: {{ 'host all all ' + scidbNameAddr  + ' md5' }} #} # TODO: parameterize subnet/mask per cluster
# TODO: learn how to extend the formulas states, may eliminate a second postgres restart
#       after overwriting hba.conf

postgres_scidb_config_postgresql_listen:
  file.replace:
  - name: {{ pillar['postgres_data_dir'] + '/postgresql.conf' }}
  - append_if_not_found: True
  - pattern: "#listen_addresses = 'localhost'"
  - repl:    "listen_addresses = '*'"

postgres_scidb_config_postgresql_port:
  file.replace:
  - name: {{ pillar['postgres_data_dir']+'/postgresql.conf' }}
  - append_if_not_found: True
  - pattern: "#port = 5432"
  - repl:    "port = 5432"

postgres_scidb_config_postgresql_connections:
  file.replace:
  - name: {{pillar['postgres_data_dir']+'/postgresql.conf' }}
  - append_if_not_found: True
  - pattern: "max_connections = .*"
  - repl:    "max_connections = 300"    # enough for 256 instances (we have 128 physical cores)

postgres_scidb_enabled:
  service.running:
    - name: {{ pillar['postgres_service'] }}
    - enable: true

{% endif %} # server-0
