#    TODO: can the actions of do_inits.sh be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

{% set KEY = pillar['scidbKEY'] %}
{% set VER = pillar['scidbVER'][KEY] %}

{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']  %}


scidb_stopall:
  cmd.run:
    - user: scidbadmin
    - name: {{ '/opt/scidb/'+VER+'/bin/scidb.py stopall test_dbname' }}
    - require:
      - cmd: scidbadmin_pgpass

{% if (serverNumber == 0 ) %}

scidb_initall:
  cmd.script:
    - name: do_inits.sh
    - user: root
    - shell: /bin/bash
    - source: salt://scidb_init/do_inits.sh 
    - template: jinja
    - require:
      - cmd: scidb_stopall

{% else %}

scidb_initall:     # a dummy state for server-1 and on 
  cmd.script:
    - name: /bin/true
    - require:
      - cmd: scidb_stopall

{% endif %}

