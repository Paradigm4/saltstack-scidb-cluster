# saltstack-scidb-cluster

This provides saltstack rules (.sls files) and templated files that allow one to set up a sscidb cluster using saaltstack

The files will be added over the next few days, so what is here won't actually be useable until this README.md file  is updated to have this message removed.

TODO: add pillar.example

When initially writing/extending state files,  you may find the following jinja examples useful.
Try evaluating these by looking at the contents of pillar.example

{% set my_ip   = grains['fqdn_ip4a'] 	%}         # e.g. 10.0.1.27
{% set my_fqdn = grains['fqdn'] %}                 # e.g. server1.cluster1.foo.com

{% set all_info = pillar['scidb_minion_info']  %}
{% set my_info = all_info[my_fqdn]  %}             # indirect through administrative fqdn to scidb-specific info

{% set scidbNameAddr = my_info['scidbNameAddr']  %} # 
{% set my_clusterName = my_info['clusterName']     %} # a string

{% set my_clusterHosts = pillar['scidb_cluster_info'][my_clusterName] %} # array of host names

{% set my_id_rsa_pub = pillar['scidbadmin_id_rsa_pub'] %}	         # a shared public key for intra-cluster ssh
