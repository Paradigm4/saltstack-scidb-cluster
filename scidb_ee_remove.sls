## Completely ignore non-RHEL based systems

{% set KEY = pillar['scidbKEY'] %}
{% set VER = pillar['scidbVER'][KEY] %}

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
      - paradigm4-repo-16-7
      - paradigm4-repo-15-12



