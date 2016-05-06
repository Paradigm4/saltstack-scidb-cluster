
scidb_firewall_off:
  cmd.run:
  - cwd: /
  - user: root
  - name: chkconfig iptables off

scidb_firewall_stop:
  cmd.run:
  - cwd: /
  - user: root
  - name: service iptables stop
  - require: 
    - cmd: scidb_firewall_off
