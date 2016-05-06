
scidbadmin_initall:
  cmd.script:
    - name: do_inits.sh
    - user: root
    - shell: /bin/bash
    - source: salt://scidb_init/do_inits.sh 
    - require:
      - cmd: scidbadmin_pgpass

