## Completely ignore non-RHEL based systems

{% set VER = pillar['scidb_ver'] %}

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
      - {{ 'scidb-'+VER+'-libboost-serialization' }}
      - {{ 'scidb-'+VER+'-libboost-system' }}
      - {{ 'scidb-'+VER+'-libboost-thread' }}
      - {{ 'scidb-'+VER+'-mpich2' }}
      - {{ 'protobuf' }}
      - {{ 'log4cxx' }}

# TODO: should not need to know version to install p4, only selecting the repo
scidb_ee_old_remove:
  pkg.removed:
    - pkgs: 
      - paradigm4-repo-15-12
      - paradigm4-repo-16-6
      - paradigm4-repo-16-7

# does not really belong in here, but it is handy to avoid mistakes
p4repo_remove:
  pkg.removed:
    - pkgs: 
      - paradigm4-repo




