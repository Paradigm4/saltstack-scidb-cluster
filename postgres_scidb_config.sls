
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
{% set listenerCIDR = pillar['scidb_cluster_info'][clusterName]['postgresListenerCIDR']  %}

# todo: can the above use ... pillar.scidb_minion_info as in YAML ?
# DEBUG TIP show_full_context()

{% if KEY == 'new' %}

# remove postgres84
scidb_postgres84_remove:
  pkg.removed:
    - pkgs:
      - postgresql
      - postgresql-contrib
      - postgresql-libs
      - postgresql-server

# and 84's data dir (else postgres93 will use /var/lib/pgsql/93/data)
scidb_postgres84_rmdir:
  file.absent:
    - name: /var/lib/pgsql/data
    - require:
      - pkg: scidb_postgres84_remove

scidb_postgres93_repo_install:
  pkg.installed:
    - name: pgdg-centos93
    - sources:
      - pgdg-centos93: https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-2.noarch.rpm
    - require:
      - file: scidb_postgres84_rmdir

scidb_postgres93_install:
  pkg.installed:
    - pkgs:
      - postgresql93
      - postgresql93-contrib
      - postgresql93-server
    - require:
      - pkg: scidb_postgres93_repo_install

# now need a service start and stuff like that

{% elif KEY == 'old' %}

# remove postgres93
scidb_postgres93_remove:
  pkg.removed:
    - pkgs:
      - pgdg-centos93
      - postgresql93
      - postgresql93-contrib
      - postgresql93-libs
      - postgresql93-server

# and 93's data dir (e.g. if someone installed 93 without removing 84)
scidb_postgres93_rmdir:
  file.absent:
    - name: /var/lib/pgsql/9.3
    - require:
      - pkg: scidb_postgres93_remove

{% else %}
    need an error here
{% endif %}


{% if serverNumber == 0 %}
 {% if KEY == 'new' %}

postgres_scidb_config_init:
  cmd.run:
  - name: service postgresql-9.3 initdb

  {% else %}

include:                   # TODO: get rid of this, its causing more trouble than its worth at this point
  - postgres               # https://github.com/saltstack-formulas/postgres-formulas

 {% endif %}

postgres_scidb_config_hba_conf:
  file.replace:
{% if KEY == 'new' %}
  - name: '/var/lib/pgsql/9.3/data/pg_hba.conf' # TODO: use postgres.conf_dir (see  pg_hba.conf formula)
{% else %}
  - name: '/var/lib/pgsql/data/pg_hba.conf'
{% endif %}
  - append_if_not_found: True
  - pattern: 'host all all * md5'               # should not be there anyway ... really this is an "append"
# TODO: this is the only way this can work for PG 8.3
  - repl: {{ 'host all all ' + listenerCIDR + ' md5' }}
# TODO: for PG 9.3 something like this might allow using the scidbNameAddr + mask 
#       or listing all the hosts in the cluster explicitly
# would need a jinja loop
# {# - repl: {{ 'host all all ' + scidbNameAddr  + ' md5' }} #} # TODO: parameterize subnet/mask per cluster
# TODO: learn how to extend the formulas states, may eliminate a second postgres restart
#       after overwriting hba.conf


#
# NOTE: for 'old'
#    pillar postgres.postgresconf must be set in e.g. /srv/pillar/data.sls to
#    "listener_address = '*' \n port = 5432"
#

{% if KEY == 'new' %}

postgres_scidb_config_postgresql_listen:
  file.replace:
  - name: '/var/lib/pgsql/9.3/data/postgresql.conf' # TODO: use postgres.conf_dir (see  pg_hba.conf formula)
  - append_if_not_found: True
  - pattern: "#listen_addresses = 'localhost'"
  - repl:    "listen_addresses = '*'"
  - require:
    - file: postgres_scidb_config_postgresql_connections

postgres_scidb_config_postgresql_port:
  file.replace:
  - name: '/var/lib/pgsql/9.3/data/postgresql.conf' # TODO: use postgres.conf_dir (see  pg_hba.conf formula)
  - append_if_not_found: True
  - pattern: "#port = 5432"
  - repl:    "port = 5432"
  - require:
    - file: postgres_scidb_config_postgresql_connections

{% endif %}

postgres_scidb_config_postgresql_connections:
  file.replace:
{% if KEY == 'new' %}
  - name: '/var/lib/pgsql/9.3/data/postgresql.conf' # TODO: use postgres.conf_dir (see  pg_hba.conf formula)
{% else %}
  - name: '/var/lib/pgsql/data/postgresql.conf'
{% endif %}
  - append_if_not_found: True
  - pattern: "max_connections = .*"
  - repl:    "max_connections = 300"    # enough for 256 instances (we have 128 physical cores)
  - require:
    - file: postgres_scidb_config_hba_conf

postgres_scidb_config_restart:
  service.running:
 {% if KEY == 'new' %}
    - name: postgresql-9.3
 {% else %}
    - name: postgresql
 {% endif %}
    - enable: true
    - require:
      - file: postgres_scidb_config_postgresql_connections

{% endif %}
