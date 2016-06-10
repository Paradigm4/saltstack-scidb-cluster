
scidb_firewall_off:
  service.dead:
{% if grains.osfinger == "CentOS Linux-7" %}
  - name: firewalld
{% else %}
  - name: iptables
{% endif %}
  - enable: False
