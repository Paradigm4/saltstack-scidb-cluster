## Completely ignore non-RHEL based systems

## A lookup table for scidb GPG keys & RPM URLs for various releases
## note confidential info in rpm

include:
  - epel      # access epel repo, uses https://github.com/saltstack-formulas/epel-formula
  - paradigm4 # access paradigm4 repo


paradigm4:   # note name for software packages in repo are likely to become "scidb" or "scidb EE"
  pkg.installed:
    - name: paradigm4-15.12-all-coord      # "scidb" packages
    - require:
      - pkg: epel_release                  # from epel
      - pkg: paradigm4_repo                # from paradgim4


