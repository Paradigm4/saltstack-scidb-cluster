
{% set KEY = pillar['scidbKEY'] %}
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
{% set clusterName  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']         %}
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']        %}
{% set listenerCIDR = pillar['scidb_cluster_info'][clusterName]['postgresListenerCIDR']  %}

{% if KEY == 'new' %}

#
# postgres packages, try making sure 9.3 is installed before hitting the postgres formula
#  in case it handles it
#
scidb_postgres84_remove:
  pkg.removed:
    - pkgs:
      - postgresql
      - postgresql-contrib
      - postgresql-libs
      - postgresql-server

scidb_postgres93_repo_install:
  pkg.installed:
    - name: pgdg-centos93
    - sources:
      - pgdg-centos93: https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-2.noarch.rpm
    - require:
      - pkg: scidb_postgres84_remove

scidb_postgres93_install:
  pkg.installed:
    - pkgs:
      - postgresql93
      - postgresql93-contrib
      - postgresql93-server
    - require:
      - pkg: scidb_postgres93_repo_install

{% elif KEY == 'old' %}

scidb_postgres93_remove:
pkg.removed:
    - pgdg-93-centos
    # - plus whatever new gets installed in 93

include:
  - postgres               # https://github.com/saltstack-formulas/postgres-formulas

{% else %}

need an error here

{% endif %}


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

postgres_scidb_config_postgresql_conf:
  file.replace:
  - name: /var/lib/pgsql/data/postgresql.conf     # TODO: use postgres.conf_dir (see  pg_hba.conf formula)
  - append_if_not_found: True
  - pattern: "max_connections = .*"
  - repl:    "max_connections = 300"    # enough for 256 instances (we have 128 physical cores)
  - require:
    - file: postgres_scidb_config_hba_conf

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
