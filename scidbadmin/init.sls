# setup scidb config.ini

{% from 'idioms.sls' import VER %}
{% from 'idioms.sls' import CLUSTER_NAME %}

# find cluster and server from administrative name (same as minion is addressed)
{% set CLUSTER_HOSTS   = pillar['scidb_cluster_info'][CLUSTER_NAME]['hosts'] %}

# DEBUG TIP show_full_context()

# go ahead and install the config.ini on all hosts in cluster

scidbadmin_user:
  user.present:
  - name: scidbadmin
  - shell: /bin/bash
  - home:  /home/scidbadmin
  - groups:
    - wheel

scidbadmin_ssh_dir:
  file.directory:
    - name: '~scidbadmin/.ssh'
    - user: scidbadmin
    - group: scidbadmin
    - mode: 700
    - makedirs: True

scidbadmin_ssh_priv:
  file.managed:
    - name: '~scidbadmin/.ssh/id_rsa'
    - makedirs: True
    - source: 'salt://scidbadmin/id_rsa'
    - user: scidbadmin
    - group: scidbadmin
    - mode: 600
    - template: jinja
    - require:
      - user: scidbadmin_user

scidbadmin_ssh_pub:
  file.managed:
    - name: '~scidbadmin/.ssh/id_rsa.pub'
    - makedirs: True
    - source: 'salt://scidbadmin/id_rsa.pub'
    - template: jinja
    - user: scidbadmin
    - group: scidbadmin
    - mode: 644
    - require:
      - file: scidbadmin_ssh_priv

scidbadmin_ssh_auth:
  file.managed:
    - name: '~scidbadmin/.ssh/authorized_keys'
    - makedirs: True
    - source: 'salt://scidbadmin/authorized_keys'
    - template: jinja
    - user: scidbadmin
    - group: scidbadmin
    - mode: 600
    - require:
      - file: scidbadmin_ssh_pub

{% for host_info in CLUSTER_HOSTS %}
{{ host_info['scidbNameAddr'] + '_known_hosts:' }}
  ssh_known_hosts:
    - present
    - user: scidbadmin
    - name: {{ host_info['scidbNameAddr'] }}
    - enc: rsa
    - hash_known_hosts: False
    - fingerprint: {{ host_info['fingerprint'] }}
{% endfor %}

scidbadmin_pgpass:
  file.managed:
    - name: '~scidbadmin/.pgpass'
    - makedirs: True
    - source: 'salt://scidbadmin/pgpass'
    - template: jinja
    - user: scidbadmin
    - group: scidbadmin
    - mode: 600
    - require:
      - user: scidbadmin_user
