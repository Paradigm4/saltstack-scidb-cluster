#    TODO: can the actions of do_inits.sh be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

{% from 'idioms.sls' import CLUSTER_NAME, VER %}

{% set HOST_NUMS  = pillar['scidb_cluster_info'][CLUSTER_NAME]['hostNums'] %}
{% set HOST_LAST_INST = pillar['scidb_cluster_info'][CLUSTER_NAME]['hostLastInst'] %}
{% set DATA_PREFIX   = pillar['scidb_cluster_info'][CLUSTER_NAME]['dataPrefix'] %}

{% set hostNum = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']  %}

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
### mount the data drives listed in host's ['dataFs'] list
###

# note: hostNum set near the top

{% for data_fs in pillar['scidb_cluster_info'][CLUSTER_NAME]['dataFs'] %}
  {% set DATA_IDX = data_fs.idx %}

  {% if DATA_PREFIX == "/mnt/data" %}
{{'unmount_device_' +DATA_PREFIX +'_' +hostNum|string +'_' +DATA_IDX|string}}:
  mount.unmounted:
  - name: {{DATA_PREFIX +DATA_IDX|string}}
  - persist: True

    {% set DATA_DEV = data_fs.dev %}
{{'mount_device_' +DATA_PREFIX +'_' +hostNum|string +'_' +DATA_IDX|string}}:
  mount.mounted:
  - name: {{DATA_PREFIX +DATA_IDX|string}}
  - device: {{DATA_DEV}}
  - fstype: xfs
  - mkmnt: True
  - opts:
    - defaults,noatime,nodiratime,nofail

    {% else %}
{{'ensure_directory_' +DATA_PREFIX +'_' +hostNum|string +'_' +DATA_IDX|string}}:
  file.directory:
    - name: {{DATA_PREFIX +DATA_IDX|string}}
    - user: scidbadmin
    - mode: 755
    {% endif %}

{% endfor %}

#
# remove and re-create data directories referenced by the config.ini
#
###
### TODO: eliminate duplication/dependence between this file and config.ini
###
{% for data_fs in pillar['scidb_cluster_info'][CLUSTER_NAME]['dataFs'] %}
  {% set DATA_IDX = data_fs.idx %}
  {% for inst in  data_fs.insts %}
data_dir_loop_debug{{'h' +hostNum|string +'_d' +DATA_IDX|string +'_i' +inst|string}}:
  cmd.run:
    - name: {{'echo h' +hostNum|string +'-d' +DATA_IDX|string +'-i' +inst|string}}

remove_{{'h' +hostNum|string +'_d' +DATA_IDX|string +'_i' +inst|string}}:
  file.absent:
    - name: {{DATA_PREFIX +DATA_IDX|string +'/' +hostNum|string+ '-' +inst|string }}

# create directories only on hosts that use them (cleanup above did them all, in case something changed)
create_{{'h' +hostNum|string +'_d' +DATA_IDX|string +'_i' +inst|string}}:
  file.directory:
    - user: scidbadmin
    - mode: 755
    - name: {{DATA_PREFIX +DATA_IDX|string +'/' +hostNum|string+ '-' +inst|string }}
  {% endfor %}
{% endfor %}
