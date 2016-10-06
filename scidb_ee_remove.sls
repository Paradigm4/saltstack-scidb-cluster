## Completely ignore non-RHEL based systems

{% from 'idioms.sls' import VER %} {# was: set VER = pillar['scidb_ver'] #}


scidb_ee_yum_clean_all:
  cmd.run:
    - name: yum clean all       # this one succeeds even when paradigm4 not currently installed

scidb_ee_yum_clean_all_p4:
  cmd.run:
    - name: yum --enablerepo=paradigm4 clean all

# TODO: should iterate over multiple VER, because 
scidb_ee_remove:
  pkg.removed:
    - pkgs: 
      # TODO: should not need to know version to install p4, only selecting the repo
      #       should matter.  this is because our package naming IS WRONG
      - {{ 'paradigm4-'+VER+'-all-coord' }}      # scidb, coordinator-capable
      - {{ 'paradigm4-'+VER+'-dev-tools' }}      # scidb test harness
      - {{ 'paradigm4-'+VER+'-client' }}      # scidb test harness
      - {{ 'paradigm4-'+VER+'-tests'     }}      # tests
      - {{ 'paradigm4-'+VER+'-p4'        }}      # p4-only plugins
      - {{ 'paradigm4-'+VER+'-p4-tests'  }}      # p4-tests
      - {{ 'paradigm4-'+VER }}                # not sure what this is
      - {{ 'scidb-'+VER+'-cityhash' }}
      - {{ 'scidb-'+VER+'-libboost-date-time' }}
      - {{ 'scidb-'+VER+'-libboost-filesystem' }}
      - {{ 'scidb-'+VER+'-libboost-regex' }}
      - {{ 'scidb-'+VER+'-libboost-program-options' }}
      - {{ 'scidb-'+VER+'-libboost-serialization' }}
      - {{ 'scidb-'+VER+'-libboost-system' }}
      - {{ 'scidb-'+VER+'-libboost-thread' }}
      - {{ 'scidb-'+VER+'-mpich2' }}
      - {{ 'protobuf' }}
      - {{ 'log4cxx' }}
      - {{ 'libpqxx' }}
      - {{ 'scidb-'+VER+'-cityhash-debuginfo' }}
      - {{ 'scidb-'+VER+'-libboost-debuginfo' }}
      - {{ 'scidb-'+VER+'-mpich2-debuginfo' }}
      - {{ 'scidb-16.6-cityhash-debuginfo' }}
      - {{ 'scidb-16.6-libboost-debuginfo' }}
      - {{ 'scidb-16.6-mpich2-debuginfo' }}

#
# to handle 15.12 on centos7, some things had to be pre-installed by rpm before yum (see scidb_ee.sls)
# so after the yum removals, we need to remove those with rpm
#
{% if VER == '15.12' and grains.osfinger == "CentOS Linux-7" %}  # have to force install of scidb because it wants postgres-84 and libpqxx-3.1
scidb_ee_rpm_remove:
  cmd.run:
    - user: root
    - name: {{ 'rpm -e paradigm4-15.12 paradigm4-15.12-dev-tools' }}
{% endif %} # end VER 15.12 and centos7

# TODO: should not need to know version to install p4, only selecting the repo
scidb_ee_all_repo_remove:
  pkg.removed:
    - pkgs: 
      - paradigm4-repo-15-7
      - paradigm4-repo-15-12
      - paradigm4-repo-16-6
      - paradigm4-repo-16-9

# does not really belong in here, but it is handy to avoid mistakes
p4repo_remove:
  pkg.removed:
    - pkgs: 
      - paradigm4-repo

# because the various test repos all claim to the be the final,
# yum thinks we have out of data repo xml files and so on.
# so when re-installing if we remove the metadata, yum forgets about that and starts fresh





