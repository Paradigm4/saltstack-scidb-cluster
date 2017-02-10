{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber'] %}

include:
  - scidb_postgres_pillar
{% if serverNumber == 0 %}
  - postgres.server
{% endif %}
  - postgres.client
