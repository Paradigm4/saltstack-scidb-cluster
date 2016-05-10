#    TODO: can the actions of the script be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)

scidbadmin_initall:
  cmd.script:
    - name: do_inits.sh
    - user: root
    - shell: /bin/bash
    - source: salt://scidb_init/do_inits.sh 
    - require:
      - cmd: scidbadmin_pgpass

