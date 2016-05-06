## Completely ignore non-RHEL based systems

## A lookup table for scidb GPG keys & RPM URLs for various releases
## note confidential info in rpm

include:
  - paradigm4 # repo access
  - epel      # repo access
  # do not include postgres, only server-0 gets it installed


# note: some of this might need to be under a "scidb service" -- model some of this after postgresql formula

paradigm4:   # note wrong name in repo, should be "scidb" or "scidbee",
             # so far I can't make it differ from package name
  pkg.installed:
    - name: paradigm4-15.12-all-coord # really "scidb" package
    - require:
      - pkg: paradigm4_repo
      - pkg: epel_release


