# saltstack-scidb-cluster

This provides saltstack rules (.sls files) and templated files that allow one to set up a sscidb cluster using saltstack.

TODO: add pillar.example

KNOWN ISSUES AND LIMITATIONS:
  + use at your own risk
  + needs pillar/salt.sls examples and documentation
  + targets CentOS/RHEL 6.x only at this time.
  + only tested on CentOS6
  + tested on
    + a 2-machine cluster with gigE networking
    + a 4-machine cluster with gigE networking
    + a 4-machine cluster with gigE (administrative) plus infiniband (scidb-only) networking





