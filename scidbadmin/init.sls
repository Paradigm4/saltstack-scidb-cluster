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

#
# TODO: put id_rsa file data into pillar
#
scidbadmin_ssh_priv:
  file.managed:
    - name: '~scidbadmin/.ssh/id_rsa'
    - makedirs: True
    - source: 'salt://scidbadmin/id_rsa'
    - template: jinja
    - user: scidbadmin
    - group: scidbadmin
    - mode: 600
    - require:
      - user: scidbadmin_user

# id_rsa.pub consists of a public key + this host
#    we will use the same key for scidbadmin everywhere in the cluster
#    for simplicity in generatating the authorized_keys file
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

# authorized_keys consists of one public key + hostname per line
#                 only the client with a correct private can validate this
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

#  TODO: scidb service ... here or in yet another directory?
