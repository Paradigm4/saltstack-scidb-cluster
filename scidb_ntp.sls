

{% set ntp = salt['pillar.get']('ntp') %}
# package ntp installed
ntp:
  pkg.installed:
    - name: {{ ntp.client }}

# config file, there or from the pillar/data

{% set ntp_conf_src = salt['pillar.get']('ntp:ntp_conf_src') %}
ntp_conf:
  file.managed:
    - name: {{ ntp.ntp_conf }}
{% if ntp_conf_src %}
    - template: jinja
    - source: {{ ntp_conf_src }}
{% endif %}
    - require:
      - pkg: {{ ntp.client }}

# start the service
{% if ntp.ntp_conf %}
ntp_running:
  service.running:
    - name: {{ ntp.service }}
    - enable: True
    - watch:
      - file: {{ ntp.ntp_conf }}
{% endif %}
