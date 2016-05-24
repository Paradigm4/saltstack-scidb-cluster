# setup scidb config.ini

{% set KEY = pillar['scidbKEY'] %}
{% set VER = pillar['scidbVER'][KEY] %}


# TODO: adjust this to be the 'basename' of the hostname
#       if its hard to stop at first number
#       just rename them to be msg_1 etc
#

#
# this rule should be on all hosts
#
scidb_config_ini:
  file.managed:
    - name: {{ '/opt/scidb/'+VER+'/etc/config.ini' }}
    - source: 'salt://scidb_config_ini/config.ini'
    - template: jinja                              # expand the hosts-in-cluster info from pillar

{% for host in [0, 1, 2, 3] %}
  {# set first_half = [ 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15] #}
  {% set first_half = [ 0,1,2,3,4,5,6,7] %}
  {# set first_half = [ 0,1,2,3] #}
  {# set first_half = [ 0,1,] #}
  {# set first_half = [ 0 ] #}
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
  {% set second_half = [8,9,10,11,12,13,14,15] %}
  {# set second_half = [4,5,6,7] #}
  {# set second_half = [2,3] #}
  {# set second_half = [1] #}
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
