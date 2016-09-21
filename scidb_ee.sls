## Completely ignore non-RHEL based systems

{% set VER = pillar['scidb_ver'] %}

include:
  - epel      # access epel repo, uses https://github.com/saltstack-formulas/epel-formula
  - paradigm4 # access paradigm4 repo

{% if VER == '15.12' and grains.osfinger == "CentOS Linux-7" %}  # have to force install of scidb because it wants postgres-84 and libpqxx-3.1
scidb_ee_get1:
  cmd.run:
    - user: root
    - name: {{ 'wget --no-verbose http://downloads.local.paradigm4.com/enterprise/15.12/2016-03-23-09ac65a-e84a0c4/centos6.3/paradigm4-15.12-0-1.x86_64.rpm -O /tmp/paradigm4-15.12-0-1.x86_64.rpm' }}

scidb_ee_get2:
  cmd.run:
    - user: root
    - name: {{ 'wget --no-verbose http://downloads.local.paradigm4.com/enterprise/15.12/2016-03-23-09ac65a-e84a0c4/centos6.3/paradigm4-15.12-dev-tools-0-1.x86_64.rpm -O /tmp/paradigm4-15.12-dev-tools-0-1.x86_64.rpm' }}

scidb_ee_rpm_install:
  cmd.run:
    - user: root
    - name: {{ 'rpm -i --nodeps /tmp/paradigm4-15.12-0-1.x86_64.rpm /tmp/paradigm4-15.12-dev-tools-0-1.x86_64.rpm' }}

{% endif %} # end VER 15.12 and centos7

scidb_ee:
  pkg.installed:
    - pkgs: 
      # TODO: should not need to know version to install p4, only selecting the repo
      #       should matter.  this is because our package naming IS WRONG
{% if VER == '15.12' and grains.osfinger == "CentOS Linux-7" %}  # have to force install of scidb because it wants postgres-84 and libpqxx-3.1
      - {{ 'paradigm4-'+VER+'-client' }}      # scidb, coordinator-capable
      - {{ 'paradigm4-'+VER+'-utils' }}      # scidb, coordinator-capable
      - {{ 'paradigm4-'+VER+'-plugins' }}      # scidb, coordinator-capable
      - {{ 'paradigm4-'+VER+'-client-python' }}      # scidb, coordinator-capable
      - {{ 'scidb-15.12-libboost-date-time' }}      # scidb, coordinator-capable
      - {{ 'scidb-15.12-libboost-filesystem' }}      # scidb, coordinator-capable
      - {{ 'scidb-15.12-libboost-serialization' }}      # scidb, coordinator-capable
      - {{ 'scidb-15.12-libboost-system' }}      # scidb, coordinator-capable
      - {{ 'scidb-15.12-libboost-program-options' }}      # scidb, coordinator-capable
      - {{ 'scidb-15.12-libboost-thread' }}      # scidb, coordinator-capable
      - {{ 'scidb-15.12-libboost-regex' }}      # scidb, coordinator-capable
      - {{ 'scidb-'+VER+'-cityhash' }}
      - {{ 'scidb-'+VER+'-mpich2' }} 
      #- {{ 'python-paramiko' }}
      #- {{ 'python-crypto' }}
      #- {{ 'python-argparse' }}
      - {{ 'openssh-clients' }}
      - {{ 'lapack' }}
      - {{ 'blas' }}
      - {{ 'libcsv' }}
      - {{ 'openssl' }}
{% else %}
      - {{ 'paradigm4-'+VER+'-all-coord' }}      # scidb, coordinator-capable
      - {{ 'paradigm4-'+VER+'-dev-tools' }}      # scidb test harness
{% endif %}
      - {{ 'paradigm4-'+VER+'-p4'        }}      # p4-only plugins, has dependency on  paradigm4-15.12 (scidb base) which interacts when that is rpm -installed for Centos7

      # the following are appearing in 15.12, and I thought in 16.6RC, so I dont' understand the "not since" comment below
      - {{ 'scidb-'+VER+'-cityhash-debuginfo' }}       # not since 15.12 release
      - {{ 'scidb-'+VER+'-libboost-debuginfo' }}       # not since 15.12 release
      - {{ 'scidb-'+VER+'-mpich2-debuginfo' }}         # not since 15.12 release

# new with 16.6RC -- tests
{% if VER != "15.12" and VER != "15.7" %}
      - {{ 'paradigm4-'+VER+'-tests'     }}      # tests
      - {{ 'paradigm4-'+VER+'-p4-tests'  }}      # p4-tests
{% endif %}

      # third party debuginfo symbols -- these are named "correctly"
      - 'libpqxx-debuginfo'
      - 'protobuf-debuginfo'
      - 'log4cxx-debuginfo'                            # not seen since 15.12 release?

# not attempting this prior to 16.6, because of dependencies on  e.g. devtoolset-3-gdb (which was wrong and was fixed)
{% if VER != "15.12" and VER != "15.7" %}
      # note, the package names need fixing to debuginfo to meet standards, I think
      - {{ 'paradigm4-'+VER+'-client-dbg' }}
      - {{ 'paradigm4-'+VER+'-client-python-dbg' }}
      - {{ 'paradigm4-'+VER+'-dbg' }}
      - {{ 'paradigm4-'+VER+'-dev-tools-dbg' }}
      - {{ 'paradigm4-'+VER+'-plugins-dbg' }}
      - {{ 'paradigm4-'+VER+'-utils-dbg' }}
{% endif %}


    - require:
      - pkg: epel_release                  # from epel
      - pkg: paradigm4_repo                # from paradgim4
