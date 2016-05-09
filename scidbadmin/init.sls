# setup scidb config.ini

include:
  - scidb_ee                       # scidb packages, in this repo

{% set my_fqdn = grains['fqdn'] %}                 # looks like msg1.local.paradigm4.com
{% set my_clusterName = pillar['scidb_minion_info'][my_fqdn]['clusterName'] %} # string
{% set my_clusterHosts = pillar['scidb_cluster_info'][my_clusterName] %} # an array of fqdns or ip addresses
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
#    TOOD: figure out if local iteration is possible
#
scidbadmin_ssh_known_hosts:
  cmd.script:
    - name: {{ 'capture_known_hosts.sh ' + my_clusterHosts|join(' ') }}  
    - user: scidbadmin
    - shell: /bin/bash
    - source: salt://scidbadmin/capture_known_hosts.sh 
    - require:
      - file: scidbadmin_ssh_auth

#
# run pgpass_updater.py (as scidbadmin) which makes the .pgpass file
#
scidbadmin_pgpass:
  cmd.script:
{% if pillar['scidb_numeric'] %}
    - name: {{ 'do_pgpass.sh ' + grains.get('fqdn_ip4', ['Y.Y.Y.Y'])[0] }}
{% else %}
    # this is broken because we need not the current fqdn, but that of server-0
    # so we need to (in jina)
    #  look up my_info
    #  look up my_cluster
    #  look up scidbNameAddr-0 
    - name: {{ 'do_pgpass.sh ' + grains.get('fqdn', ['foo.local.xyzzy.com']) }}
{% endif %}
    - user: root
    - shell: /bin/bash
    - source: salt://scidbadmin/do_pgpass.sh 
    - require:
      - cmd: scidbadmin_ssh_known_hosts

#  TODO: scidb service ... here or in yet another directory?
