## Completely ignore non-RHEL based systems

{% set VER = pillar['scidb_ver'] %}

include:
  - epel      # access epel repo, uses https://github.com/saltstack-formulas/epel-formula
  - paradigm4 # access paradigm4 repo


scidb_ee:
  pkg.installed:
    - pkgs: 
      # TODO: should not need to know version to install p4, only selecting the repo
      #       should matter.  this is because our package naming IS WRONG
      - {{ 'paradigm4-'+VER+'-all-coord' }}      # scidb, coordinator-capable
      - {{ 'paradigm4-'+VER+'-dev-tools' }}      # scidb test harness
      - {{ 'paradigm4-'+VER+'-tests'     }}      # tests
      - {{ 'paradigm4-'+VER+'-p4'        }}      # p4-only plugins
      - {{ 'paradigm4-'+VER+'-p4-tests'  }}      # p4-tests
      # debuginfo - symbols
      # note, in the first set, the package names need fixing to debuginfo
      - {{ 'paradigm4-'+VER+'-client-dbg' }}
      - {{ 'paradigm4-'+VER+'-client-python-dbg' }}
      - {{ 'paradigm4-'+VER+'-dbg' }}
      - {{ 'paradigm4-'+VER+'-dev-tools-dbg' }}
      - {{ 'paradigm4-'+VER+'-plugins-dbg' }}
      - {{ 'paradigm4-'+VER+'-utils-dbg' }}
      # debuginfo symbols
      - 'libpqxx-debuginfo'
      - 'protobuf-debuginfo'
      # the following were in the 15.12 repo, but not in 16.6RC, for c6 or c7
      - 'log4cxx-debuginfo'                            # not seen since 15.12 release
      - {{ 'scidb-'+VER+'-cityhash-debuginfo' }}       # not since 15.12 release
      - {{ 'scidb-'+VER+'-libboost-debuginfo' }}       # not since 15.12 release
      - {{ 'scidb-'+VER+'-mpich2-debuginfo' }}         # not since 15.12 release

    - require:
      - pkg: epel_release                  # from epel
      - pkg: paradigm4_repo                # from paradgim4


