# setup scidb config.ini

include:
  - scidb_ee                       # scidb packages, in this repo


# find cluster and server from administrative name (same as minion is addressed)
{% set myClusterName  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']  %}
{% set knownHostsList = pillar['scidb_cluster_info'][myClusterName]['knownHostsList'] %}
{% set pgHostNameAddr = pillar['scidb_cluster_info'][myClusterName]['hosts'][0]['scidbNameAddr'] %}

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
    - template: jinja  # expand the the file with private key data kept in pillar
    - user: scidbadmin
    - group: scidbadmin
    - mode: 600
    - require:
      - user : scidbadmin_user

# id_rsa.pub consists of a public key + this host
#    we will use the same key for scidbadmin everywhere in the cluster
#    for simplicity in generatating the authorized_keys file
scidbadmin_ssh_pub:
  file.managed:
    - name: '~scidbadmin/.ssh/id_rsa.pub'
    - makedirs: True
    - source: 'salt://scidbadmin/id_rsa.pub'
    - template: jinja  # expand the the file with pub key data kept in pillar
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
    - template: jinja  # expand the the file with pub key data kept in pillar
    - user: scidbadmin
    - group: scidbadmin
    - mode: 600
    - require:
      - file : scidbadmin_ssh_pub

#
# known_hosts consists of a public key per host.  only the real host
#    can validate that with the private key which we don't have handy
#    so we will use 'ssh -o StrickHostKeyChecking=no <host> true' as a way to fill it in
#    don't know how to iterate over my_clusterHosts, so join into a string
#    separated by spaces and have a shell script do it
#    TODO: figure out if local iteration is possible
#    TODO: can the actions of the script be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)
#
scidbadmin_ssh_known_hosts:
  cmd.script:
    - name: {{ 'capture_known_hosts.sh ' + knownHostsList|join(' ') }}  
    - user: scidbadmin
    - shell: /bin/bash
    - source: salt://scidbadmin/capture_known_hosts.sh 
    - require:
      - file: scidbadmin_ssh_auth

#
# run pgpass_updater.py (as scidbadmin) which makes the .pgpass file
#
#    TODO: can the actions of the script be incorporated directly into this file without
#          making this file too cumbersome (e.g. perhaps we can do multiple actions per state?)
#
scidbadmin_pgpass:
  cmd.script:
    # need the scidbNameAddr for the cluster's server-0
    - name: {{ 'do_pgpass.sh ' + pgHostNameAddr }}
    - user: root
    - shell: /bin/bash
    - source: salt://scidbadmin/do_pgpass.sh 
    - require:
      - cmd: scidbadmin_ssh_known_hosts

#  TODO: scidb service ... here or in yet another directory?
