{% from 'idioms.sls' import VER %} {# was: set VER = pillar['scidb_ver'] #}

include:
  - epel      # access epel repo, uses https://github.com/saltstack-formulas/epel-formula
  - paradigm4 # access paradigm4 repo

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

scidb_ee:
  pkg.installed:
    - pkgs: 
      - {{ 'paradigm4-'+VER+'-all-coord' }}      # scidb, coordinator-capable
      - {{ 'paradigm4-'+VER+'-dev-tools' }}      # scidb test harness
      - {{ 'paradigm4-'+VER+'-p4'        }}      # p4-only plugins, has dependency on  paradigm4-15.12 (scidb base) which interacts when that is rpm -installed for Centos7

      - {{ 'scidb-'+VER+'-cityhash-debuginfo' }}
      - {{ 'scidb-'+VER+'-libboost-debuginfo' }}
      - {{ 'scidb-'+VER+'-mpich2-debuginfo' }}
{% if VER != "15.12" and VER != "15.7" %}
      - {{ 'paradigm4-'+VER+'-tests'     }}      # tests
      - {{ 'paradigm4-'+VER+'-p4-tests'  }}      # p4-tests
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
      - pkg: epel-release                  # from epel
      - pkg: paradigm4_repo                # from paradigm4
{% if VER == "15.12" or VER == "15.7" %}
      - pkg: devtoolset-3-gdb
{% endif %}
