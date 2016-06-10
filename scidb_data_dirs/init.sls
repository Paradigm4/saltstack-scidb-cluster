#    TODO: can the actions of do_inits.sh be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

{% set VER = pillar['scidb_ver'] %}

{% set my_cluster = pillar['scidb_minion_info'][grains['fqdn']]['clusterName'] %}
{% set HOST_NUMS  = pillar['scidb_cluster_info'][my_cluster]['hostNums'] %}

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
/mnt/data0:
  mount.mounted:
  - device: /dev/nvme0n1p1
  - fstype: xfs
  - mkmnt: True

/mnt/data1:
  mount.mounted:
  - device: /dev/nvme1n1p1
  - fstype: xfs
  - mkmnt: True

#
# remove and re-create data directories referenced by the config.ini
#

#
# TODO: eliminate duplication/dependence between this file and config.ini
# TODO: eliminate the host loop here
#
{% for host in HOST_NUMS %}
  {# set first_half = [ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15] #}
  {# set first_half = [ 0,1,2,3,4,5,6,7] #}
  {# set first_half = [ 0,1,2,3] #}
  {# set first_half = [ 0,1,] #}
  {% set first_half = [ 0 ] %}
  {% for inst in first_half %}
{{'remove_' +host|string+ '-' +inst|string+ ":" }}
  file.absent:
{{'  - name: /mnt/data0/' +host|string+ '-' +inst|string }}

{{'/mnt/data0/' +host|string+ '-' +inst|string+ ":" }}
  file.directory:
    - user: scidbadmin
    - mode: 755
  {% endfor %}
  {# set second_half = [16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31] #}
  {# set second_half = [8,9,10,11,12,13,14,15] #}
  {# set second_half = [4,5,6,7] #}
  {# set second_half = [2,3] #}
  {% set second_half = [1] %}
  {% for inst in second_half %}
{{'remove_' +host|string+ '-' +inst|string+ ":" }}
  file.absent:
{{'  - name: /mnt/data1/' +host|string+ '-' +inst|string }}

{{'/mnt/data1/' +host|string+ '-' +inst|string+ ":" }}
  file.directory:
    - user: scidbadmin
    - mode: 755
  {% endfor %}
{% endfor %}
