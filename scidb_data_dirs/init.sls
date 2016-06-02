#    TODO: can the actions of do_inits.sh be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

{% set VER = pillar['scidb_ver'] %}

scidb_stopall:
  cmd.run:
    - user: scidbadmin
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py stopall test_dbname' }}

scidb_base_path_init:
  cmd.script:
    - name: do_base_path.sh
    - user: root
    - shell: /bin/bash
    - source: salt://scidb_data_dirs/do_base_path.sh 
    - template: jinja

#
# remove and re-create mounted data directories
#

#
# TODO: eliminate duplication/dependence between this file and config.ini
# TODO: eliminate the host loop here
#
{% for host in [0, 1, 2, 3] %}
  {# set first_half = [ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15] #}
  {# set first_half = [ 0,1,2,3,4,5,6,7] #}
  {# set first_half = [ 0,1,2,3] #}
  {# set first_half = [ 0,1,] #}
  {% set first_half = [ 0 ] %}
  {% for inst in first_half %}
{{'remove_' +host|string+ '-' +inst|string+ ":" }}
  file.absent:
{{'  - name: /data0/' +host|string+ '-' +inst|string }}

{{'/data0/' +host|string+ '-' +inst|string+ ":" }}
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
{{'  - name: /data1/' +host|string+ '-' +inst|string }}

{{'/data1/' +host|string+ '-' +inst|string+ ":" }}
  file.directory:
    - user: scidbadmin
    - mode: 755
  {% endfor %}
{% endfor %}
