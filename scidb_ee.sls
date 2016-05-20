## Completely ignore non-RHEL based systems

{% set KEY = pillar['scidbKEY'] %}
{% set VER = pillar['scidbVER'][KEY] %}

include:
  - epel      # access epel repo, uses https://github.com/saltstack-formulas/epel-formula
  - paradigm4 # access paradigm4 repo


scidb_ee:
  pkg.installed:
    - pkgs: 
      # TODO: should not need to know version to install p4, only selecting the repo
      #       should matter.  this is because our package naming IS WRONG
      - {{ 'paradigm4-'+VER+'-all-coord' }}      # scidb, coordinator-capable
      - {{ 'paradigm4-'+VER+'-p4'        }}      # p4-only plugins
      - {{ 'paradigm4-'+VER+'-dev-tools' }}      # scidb test harness
    - require:
      - pkg: epel_release                  # from epel
      - pkg: paradigm4_repo                # from paradgim4

