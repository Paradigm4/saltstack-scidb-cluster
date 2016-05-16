## Completely ignore non-RHEL based systems

## A lookup table for scidb GPG keys & RPM URLs for various releases
## note confidential info in rpm

include:
  - epel      # access epel repo, uses https://github.com/saltstack-formulas/epel-formula
  - paradigm4 # access paradigm4 repo


scidb_ee:
  pkg.installed:
    - pkgs: 
      - paradigm4-15.12-all-coord      # scidb, coordinator-capable
      - paradigm4-15.12-p4             # p4-only plugins
    - require:
      - pkg: epel_release                  # from epel
      - pkg: paradigm4_repo                # from paradgim4

