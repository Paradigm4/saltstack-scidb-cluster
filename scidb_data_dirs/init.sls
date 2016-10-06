#    TODO: can the actions of do_inits.sh be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

{% from 'idioms.sls' import CLUSTER_NAME, VER %}
{% from 'idioms.sls' import REPO_CREDS, REPO_SCHEME, REPO_KEY, REPO_KEY_HASH, REPO_RPM %}

{% set HOST_NUMS  = pillar['scidb_cluster_info'][CLUSTER_NAME]['hostNums'] %}
{% set HOST_LAST_INST = pillar['scidb_cluster_info'][CLUSTER_NAME]['hostLastInst'] %}
{% set DATA_0_INSTS  = pillar['scidb_cluster_info'][CLUSTER_NAME]['data0insts'] %}
{% set DATA_1_INSTS  = pillar['scidb_cluster_info'][CLUSTER_NAME]['data1insts'] %}
{% set DATA_PREFIX   = pillar['scidb_cluster_info'][CLUSTER_NAME]['dataPrefix'] %}

# this hangs on a clean install on centos7, maybe be casue there's never been an init?
# I don't think this was strictly necessary, I think I put this in an attempt to be clean
#scidb_stopall:
#  cmd.run:
#    - user: scidbadmin
#    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py stopall test_dbname' }}

scidb_base_path_init:
  cmd.script:
    - name: do_base_path.sh
    - user: root
    - shell: /bin/bash
    - source: salt://scidb_data_dirs/do_base_path.sh 
    - template: jinja

#
# make sure that data drives are mounted
#

###
### TODO: learn how to make fancier jinja "if" comparisons
###       like length of list to decide whether there is
###       a list of device needing to be mounted
###       until then, let the variable be just True or False
###       and have it mount or not mount two fixed-name devices
###

{% if DATA_PREFIX == "/mnt/data" %}   # otherwise typically /home/data

{{DATA_PREFIX}}0:
  mount.mounted:
  - device: /dev/nvme0n1p1
  - fstype: xfs
  - mkmnt: True

{{DATA_PREFIX}}1:
  mount.mounted:
  - device: /dev/nvme1n1p1
  - fstype: xfs
  - mkmnt: True

{% else %}

{{DATA_PREFIX}}0:
  file.directory:
    - user: scidbadmin
    - mode: 755

{{DATA_PREFIX}}1:
  file.directory:
    - user: scidbadmin
    - mode: 755

{% endif %}

#
# remove and re-create data directories referenced by the config.ini
#

#
# TODO: eliminate duplication/dependence between this file and config.ini
# TODO: eliminate the host loop here
#
{% for host in HOST_NUMS %}
  {% for inst in DATA_0_INSTS %}
remove_0_{{ host|string+ '-' +inst|string+ ":" }}
  file.absent:
  - name: {{DATA_PREFIX +'0/' +host|string+ '-' +inst|string }}

create_0_{{ host|string+ '-' +inst|string+ ":" }}
  file.directory:
    - user: scidbadmin
    - mode: 755
    - name: {{DATA_PREFIX +'0/' +host|string+ '-' +inst|string }}
  {% endfor %}
  {% for inst in DATA_1_INSTS %}
remove_1_{{ host|string+ '-' +inst|string+ ":" }}
  file.absent:
  - name: {{DATA_PREFIX +'1/' +host|string+ '-' +inst|string }}

create_1_{{ host|string+ '-' +inst|string+ ":" }}
  file.directory:
    - user: scidbadmin
    - mode: 755
    - name: {{DATA_PREFIX +'1/' +host|string+ '-' +inst|string }}
  {% endfor %}
{% endfor %}
