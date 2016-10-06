
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
{% from 'idioms.sls' import CLUSTER_NAME, PG_REPO_NAME, PG_REPO_SOURCES, PG_PKGS, PG_DATA_DIR, PG_SERVICE %}
{% from 'idioms.sls' import PG_OTHER_REPO_NAME, PG_OTHER_PKGS, PG_OTHER_DATA_DIR, PG_OTHER_SERVICE %}

{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']        %}
{% set PG_LISTEN_CIDR = pillar['scidb_cluster_info'][CLUSTER_NAME]['postgresListenerCIDR']  %}

# todo: can the above use ... pillar.scidb_minion_info as in YAML ?
# DEBUG TIP show_full_context()

{% if serverNumber == 0 %}

# stop the existing service, before making changes
postgres_scidb_stopped:
  service.dead:
    - name: {{ PG_SERVICE }}

# also stop the other installation's service in case we are changing
# having the other type of service still running will block the port to bring the current one's type up
postgres_scidb_other_stopped:
  service.dead:
    - name: {{ PG_OTHER_SERVICE }}

{% endif %}

# remove prior version of postgres
scidb_postgres_other_remove:
  pkg.removed: 
    - pkgs: {{ PG_OTHER_PKGS }}  # other versions that might have been installed
    ## overkill: causes the right version of scidb to be removed too
    ##- pkgs: {{ PG_PKGS }}  # the version being installed

# remove prior repo of postgres
scidb_postgres_repo_other_remove:
  pkg.removed:
    - name: {{ PG_OTHER_REPO_NAME }}  # other versions that might have been installed
    ## overkill: causes the right version of scidb to be removed too
    ##- name: {{ PG_REPO_NAME }}  # the version being installed

# install the current desired version
scidb_postgres_repo_install:
  pkg.installed:
    - name: {{ PG_REPO_NAME}}
    - sources: {{ PG_REPO_SOURCES }}

scidb_postgres_install:
  pkg.installed:
    - pkgs: {{ PG_PKGS }}


# now need a service start and stuff like that
{% if serverNumber == 0 %}   # applies to server-0 only

## remove data directories from 'other' postgres releases
scidb_postgres_rmdir_other:
  file.absent:
    - name: {{ PG_OTHER_DATA_DIR }}

# remove current config directory to be replaced by
# o postgresl93-setup initdb or
# o service postgres-8.4 initdb
# o service postgres initdb
#
scidb_postgres_rmdir:
  file.absent:
    - name: {{ PG_DATA_DIR }}

# and now do the default configuration of the data directory
postgres_scidb_init:
  cmd.run:
{% if grains['init'] == "systemd" %}
    - name: /usr/pgsql-9.3/bin/postgresql93-setup initdb
    # postgres84
    #- name: "runuser -u postgres /usr/pgsql-8.4/bin/initdb  -D /var/lib/pgsql/8.4/data/"
    #- name: service {{ PG_SERVICE }} initdb
{% else %}
    - name: service {{ PG_SERVICE }} initdb # won't work until service is started
{% endif %}

postgres_scidb_config_hba_conf:
  file.replace:
  - name: {{ PG_DATA_DIR + '/pg_hba.conf' }}
  - append_if_not_found: True
  - pattern: 'host all all [^ ]* md5'               # should not be there anyway ... really this is an "append"
  - repl: {{ 'host all all ' + PG_LISTEN_CIDR + ' md5' }}

# TODO: the above is the only way this can work for PG 8.3
# TODO: but for PG 9.3 something like the following might allow using the scidbNameAddr + mask 
#       or listing all the hosts in the cluster explicitly
# - would need to if/else on the version being installed
# - would need a jinja loop
# {# - repl: {{ 'host all all ' + scidbNameAddr  + ' md5' }} #} # TODO: parameterize subnet/mask per cluster
# TODO: learn how to extend the formulas states, may eliminate a second postgres restart
#       after overwriting hba.conf

postgres_scidb_config_postgresql_listen:
  file.replace:
  - name: {{ PG_DATA_DIR + '/postgresql.conf' }}
  - append_if_not_found: True
  - pattern: "#listen_addresses = 'localhost'"
  - repl:    "listen_addresses = '*'"

postgres_scidb_config_postgresql_port:
  file.replace:
  - name: {{ PG_DATA_DIR + '/postgresql.conf' }}
  - append_if_not_found: True
  - pattern: "#port = 5432"
  - repl:    "port = 5432"

postgres_scidb_config_postgresql_connections:
  file.replace:
  - name: {{ PG_DATA_DIR + '/postgresql.conf' }}
  - append_if_not_found: True
  - pattern: "max_connections = .*"
  - repl:    "max_connections = 300"    # enough for 256 instances (we have 128 physical cores)

postgres_scidb_enabled:
  service.running:
    - name: {{ PG_SERVICE }}
    - enable: true

{% endif %} # server-0
