#    TODO: can the actions of do_inits.sh be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

{% from 'idioms.sls' import CLUSTER_NAME, VER %}
{% from 'idioms.sls' import REPO_CREDS, REPO_SCHEME, REPO_KEY, REPO_KEY_HASH, REPO_RPM %}

{% set HOST_NUMS  = pillar['scidb_cluster_info'][CLUSTER_NAME]['hostNums'] %}
{% set HOST_LAST_INST = pillar['scidb_cluster_info'][CLUSTER_NAME]['hostLastInst'] %}
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

{% for host in HOST_NUMS %}
  {% for data_fs in pillar['scidb_cluster_info'][CLUSTER_NAME]['dataFs'] %}
    {% set DATA_IDX = data_fs.idx %}
    {% set DATA_DEV = data_fs.dev %}

    {% if DATA_PREFIX == "/mnt/data" %}
{{'unmount_device_' +DATA_PREFIX +'_' +host|string +'_' +DATA_IDX|string}}:
  mount.unmounted:
  - name: {{DATA_PREFIX +DATA_IDX|string}}
  - persist: True

{{'mount_device_' +DATA_PREFIX +'_' +host|string +'_' +DATA_IDX|string}}:
  mount.mounted:
  - name: {{DATA_PREFIX +DATA_IDX|string}}
  - device: {{DATA_DEV}}
  - fstype: xfs
  - mkmnt: True

    {% else %}
{{'ensure_directory_' +DATA_PREFIX +'_' +host|string +'_' +DATA_IDX|string}}:
  file.directory:
    - name: {{DATA_PREFIX +DATA_IDX|string}}
    - user: scidbadmin
    - mode: 755
    {% endif %}

  {% endfor %}
{% endfor %}

#
# remove and re-create data directories referenced by the config.ini
#
# TODO: eliminate duplication/dependence between this file and config.ini
#

{% for host in HOST_NUMS %}
  {% for data_fs in pillar['scidb_cluster_info'][CLUSTER_NAME]['dataFs'] %}
    {% set DATA_IDX = data_fs.idx %}
    {% for inst in  data_fs.insts %}
data_dir_loop_debug{{'h' +host|string +'_d' +DATA_IDX|string +'_i' +inst|string}}:
  cmd.run:
    - name: {{'echo h' +host|string +'-d' +DATA_IDX|string +'-i' +inst|string}}

remove_{{'h' +host|string +'_d' +DATA_IDX|string +'_i' +inst|string}}:
  file.absent:
    - name: {{DATA_PREFIX +DATA_IDX|string +'/' +host|string+ '-' +inst|string }}

# TODO: to eliminate a lot of unused directores ...
# TODO: when actually creating, only do so if the host number is the one the minion is running on
# if host == this host  (from grains?)

create_{{'h' +host|string +'_d' +DATA_IDX|string +'_i' +inst|string}}:
  file.directory:
    - user: scidbadmin
    - mode: 755
    - name: {{DATA_PREFIX +DATA_IDX|string +'/' +host|string+ '-' +inst|string }}
    {% endfor %}
  {% endfor %}
{% endfor %}
