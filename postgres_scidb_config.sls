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

{% set my_fqdn = grains['fqdn'] %}
{% set scidbNameAddr = pillar['scidb_minion_info'][my_fqdn]['scidbNameAddr']  %} # FQDN or IP addr

# todo: can the above use ... pillar.scidb_minion_info as in YAML ?
# DEBUG TIP show_full_context()


postgres_scidb_config_hba_conf:
  file.replace:
  - name: /var/lib/pgsql/data/pg_hba.conf     # TODO: use postgres.conf_dir (see  pg_hba.conf formula)
  - append_if_not_found: True
  - pattern: "host all all * md5"               # should not be there anyway ... really this is an "append"
# TODO: this is the only way this can work for PG 8.3, requires PG 9.3 to use hostnames
  - repl: {{ 'host all all 10.0.16.0/20 md5' }} # TODO: parameterize subnet/mask per cluster
  - require:
    - file: pg_hba.conf
# IP VS NAME
# the following would need to be in a jinja loop once using PG 9.3
# - repl: {{ 'host all all ' + scidbNameAddr  + ' md5' }} # TODO: parameterize subnet/mask per cluster
# we would also select using jinja if scidb_numeric / else / endif jinja

# TODO: need to learn how to extend the original states rather than
#       to overwrite hba.conf, which requries the postgres restart

#
# NOTE:
#    pillar postgres.postgresconf must be set in e.g. /srv/pillar/data.sls to
#    "listener_address = '*' \n port = 5432"
#
postgres_scidb_config_postgresql_conf:
  file.replace:
  - name: /var/lib/pgsql/data/postgresql.conf     # TODO: use postgres.conf_dir as in postgres formuals ?
  - append_if_not_found: False
  - pattern: "foo"                                # we don't really need this state, so we are tricking it
  - repl:    "foo"
  - require:
    - file: postgresql-conf

# fake to make postgres_scidb_config be a rule
postgres_scidb_config:
  file.replace:
  - name: /var/lib/pgsql/data/postgresql.conf     # TODO: use postgres.conf_dir as in postgres formuals ?
  - append_if_not_found: False
  - pattern: "foo"                                # we don't really need this state, so we are tricking it
  - repl:    "foo"
  - require:
    - file: postgres_scidb_config_postgresql_conf

# todo: cmd.run -> service.running (see p4_pxeboot)
postgres_scidb_config_restart:
  cmd.run:
  - cwd: /
  - user: root
  - name: service postgresql restart
  - require:
    - file: postgres_scidb_config_hba_conf
    - file: postgres_scidb_config
    - service: run-postgresql
