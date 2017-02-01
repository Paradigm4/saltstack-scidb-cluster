### BEGIN IDIOMS ###

{% set CLUSTER_NAME   = pillar.scidb_minion_info[grains['fqdn']]['clusterName']  %}

# cluster_info lookups
{% set INST_CHOICE    = pillar.scidb_cluster_info[CLUSTER_NAME].install_choice %}

# install_choices lookups
{% set REPO_RPM       = pillar.scidb_install_choices[INST_CHOICE].p4repo_rpm      %}
{% set INST_GROUP     = pillar.scidb_install_choices[INST_CHOICE].install_group   %}

# install_groups lookups
{% set REPO_SCHEME    = pillar.scidb_install_groups[INST_GROUP].p4repo_scheme %}
{% set REPO_CREDS     = pillar.scidb_install_groups[INST_GROUP].p4repo_creds %}
{% set REPO_KEY       = pillar.scidb_install_groups[INST_GROUP].p4repo_key %}
{% set REPO_KEY_HASH  = pillar.scidb_install_groups[INST_GROUP].p4repo_key_hash %}
{% set VER            = pillar.scidb_install_groups[INST_GROUP].scidb_ver %}  # later change to SCIDB_VER
{% set INST_DIR       = pillar.scidb_install_groups[INST_GROUP].scidb_inst_dir %} 
{% set INST_SERVICE   = pillar.scidb_install_groups[INST_GROUP].scidb_service %} 

{% set REPO_RPM_URI   = REPO_SCHEME + '//' + REPO_CREDS + REPO_RPM %}
{% set REPO_KEY_URI   = REPO_SCHEME + '//' + REPO_CREDS + REPO_KEY %}

{% set INST_PGVER     = pillar.scidb_install_groups[INST_GROUP].pg_ver %}

# p4repo_pkgname in a choice overrides p4repo_pkgname in a group
{% if pillar.scidb_install_choices[INST_CHOICE].p4repo_pkgname is defined %}
{% set REPO_PKGNAME   = pillar.scidb_install_choices[INST_CHOICE].p4repo_pkgname %}
{% else %}
{% set REPO_PKGNAME   = pillar.scidb_install_groups[INST_GROUP].p4repo_pkgname %}
{% endif %}

# pg_info lookups
{% set PG_REPO_NAME       = pillar.scidb_pg_info[INST_PGVER].repo_name %}
{% set PG_REPO_SOURCES    = pillar.scidb_pg_info[INST_PGVER].repo_sources %}
{% set PG_PKGS            = pillar.scidb_pg_info[INST_PGVER].pkgs %}
{% set PG_SERVICE         = pillar.scidb_pg_info[INST_PGVER].service %}
{% set PG_DATA_DIR        = pillar.scidb_pg_info[INST_PGVER].data_dir %}
{% set PG_OTHER_REPO_NAME = pillar.scidb_pg_info[INST_PGVER].other_repo_name %}
{% set PG_OTHER_PKGS      = pillar.scidb_pg_info[INST_PGVER].other_pkgs %}
{% set PG_OTHER_SERVICE   = pillar.scidb_pg_info[INST_PGVER].other_service %}
{% set PG_OTHER_DATA_DIR  = pillar.scidb_pg_info[INST_PGVER].other_data_dir %}

### END IDIOMS ###

