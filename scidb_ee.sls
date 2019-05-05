{% from 'idioms.sls' import VER %} {# was: set VER = pillar['scidb_ver'] #}

include:
  - epel      # access epel repo, uses https://github.com/saltstack-formulas/epel-formula
  - scidb3rdparty_repo # access scidb3rdparty repo
  - paradigm4_repo # access paradigm4 repo

{% if VER == "15.12" or VER == "15.7" %}

centos-release-scl:
  pkg.installed

devtoolset-3-gdb:
  pkg.installed:
  - require:
    - pkg: centos-release-scl

libpqxx-3.1:
  pkg.installed:
  - pkgs:
    - libpqxx-3.1
  - check_cmd:     # Do not know why this state returns false even thought the lib is installed
      - /bin/true  # Override the False return

{% endif %}
#
# This removal of libpqxx is to remedy the "help" postgres-formula
# provides when it, in addition to installing the postgres client,
# installs libpq-develop. It gets the latest version which is 5.0
# which conflicts with scidb's requirement of 4.0.1
#
# Since the installation of libpq-develop by postgres-formula
# has not dependency the removal gets not "objections"
# and clears the way for scidb installation.
#
remove-libpqxx-5.0:
  pkg.removed:
    - pkgs: 
      - libpqxx: '>=5.0'

scidb_ee:
  pkg.installed:
    - skip_verify: True
    - pkgs: 
      - {{ 'paradigm4-'+VER+'-all' }}      # scidb, coordinator-capable
      - {{ 'paradigm4-'+VER+'-dev-tools' }}      # scidb test harness
      - {{ 'paradigm4-'+VER+'-p4'        }}      # p4-only plugins, has dependency on  paradigm4-15.12 (scidb base) which interacts when that is rpm -installed for Centos7

      - {{ 'scidb-'+VER+'-cityhash-debuginfo' }}
      - {{ 'scidb-'+VER+'-libboost-debuginfo' }}
{% if VER < "17.9" %}
      - {{ 'scidb-'+VER+'-mpich2-debuginfo' }}
{% else %}
      - 'mpich2scidb-debuginfo'
{% endif %}
      # third party debuginfo symbols
      - 'libpqxx-debuginfo'
      - 'protobuf-debuginfo'
      - 'log4cxx-debuginfo'

      - {{ 'paradigm4-'+VER+'-client-dbg' }}
      - {{ 'paradigm4-'+VER+'-client-python-dbg' }}
      - {{ 'paradigm4-'+VER+'-dbg' }}
      - {{ 'paradigm4-'+VER+'-dev-tools-dbg' }}
      - {{ 'paradigm4-'+VER+'-plugins-dbg' }}
      - {{ 'paradigm4-'+VER+'-utils-dbg' }}

    - require:
      - pkg: epel_release                  # from epel
      - pkg: paradigm4_repo                # from paradigm4
{% if VER == "15.12" or VER == "15.7" %}
      - pkg: devtoolset-3-gdb
{% endif %}
