### BEGIN IDIOMS ###

{% set CLUSTER_NAME   = pillar.scidb_minion_info[grains['fqdn']]['clusterName']  %}

# cluster_info lookups
{% set INST_CHOICE    = pillar.scidb_cluster_info[CLUSTER_NAME].install_choice %}

# install_choices lookups
{% set REPO_URL       = pillar.scidb_install_choices[INST_CHOICE].p4repo_url      %}
{% set REPO_KEY       = pillar.scidb_install_choices[INST_CHOICE].p4repo_key      %}
{% set INST_GROUP     = pillar.scidb_install_choices[INST_CHOICE].install_group   %}

# install_groups lookups
{% set VER            = pillar.scidb_install_groups[INST_GROUP].scidb_ver %}  {# later change to SCIDB_VER #}
{% set INST_DIR       = pillar.scidb_install_groups[INST_GROUP].scidb_inst_dir %} 
{% set INST_SERVICE   = pillar.scidb_install_groups[INST_GROUP].scidb_service %} 

{% set INST_PGVER     = pillar.scidb_install_groups[INST_GROUP].pg_ver %}

### END IDIOMS ###

