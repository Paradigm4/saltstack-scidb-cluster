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
      - {{ 'paradigm4-'+VER+'-p4'        }}      # p4-only plugins

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
