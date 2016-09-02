## Completely ignore non-RHEL based systems

{% set VER = pillar['scidb_ver'] %}


scidb_ee_yum_clean_metadata:
  cmd.run:
    - name: yum --enablerepo=paradigm4 clean metadata 

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

# TODO: should not need to know version to install p4, only selecting the repo
scidb_ee_old_remove:
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





