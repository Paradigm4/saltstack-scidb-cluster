# copy plugins from pillar-specified location into the installation's plugins directory

{% from 'idioms.sls' import VER %}
{% from 'idioms.sls' import CLUSTER_NAME %}

# find cluster and server from administrative name (same as minion is addressed)
{% set KNOWN_HOSTS_LIST = pillar['scidb_cluster_info'][CLUSTER_NAME]['knownHostsList'] %}
{% set PG_HOST_NAME_ADDR = pillar['scidb_cluster_info'][CLUSTER_NAME]['hosts'][0]['scidbNameAddr'] %}

{% set EXTRA_PLUGINS_TAR = pillar['scidb_cluster_info'][CLUSTER_NAME]['extra_plugins_tar'] %}


# DEBUG TIP show_full_context()

scidb_extra_plugins_pre:
  cmd.run:
    - name: {{ 'ls -l /opt/scidb/' + VER + '/lib/scidb/plugins' }}
    - shell: /bin/bash

scidb_extra_plugins_extracted:
  # can't do the following, because EXTRA_PLUGINS_TAR is not salt-relative, so it balks
  #archive.extracted:
    #- name: {{ '/opt/scidb/' + VER + '/lib/scidb/plugins' }}
    #- source: {{ EXTRA_PLUGINS_TAR }}          # EXTRA_PLUGINS_TAR=/public/plugins17.1/p4github_jason_17.1.tar (or .tgz) for example
    #- archive_format: tar
  cmd.run:
    - cwd: {{ '/opt/scidb/' + VER + '/lib/scidb/plugins' }}
    - name: {{ 'tar xvf ' + EXTRA_PLUGINS_TAR }}

scidb_extra_plugins_post:
  cmd.run:
    - name: {{ 'ls -l /opt/scidb/' + VER + '/lib/scidb/plugins' }}
    - shell: /bin/bash

