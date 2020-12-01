# scidb_ee_remove.sls
{% from 'idioms.sls' import VER %}

{% if VER > "18.2" %}
#
# With 19.3 onwards all 3rdparty packages are now in the paradigm4 repository
# not separately in scidb3rdparty
#
{% else %}
scidb_ee_remove_yum_clean_all:
  cmd.run:
    - name: yum --enablerepo=scidb3rdparty clean all
{% endif %}

scidb_ee_remove_yum_clean_cache:
  cmd.run:
    - name: rm -rf /var/cache/yum

scidb_ee_remove_yum_erase_paradigm4_pkgs:
  cmd.run:
    - name: yum list installed | grep -i paradigm4 | awk '{print $1}' | grep '[a-zA-Z]' | xargs yum -y remove

scidb_ee_remove_yum_erase_scidb_pkgs:
  cmd.run:
    - name: yum list installed | grep -i scidb | awk '{print $1}' | grep '[a-zA-Z]' | xargs yum -y remove

scidb_ee_remove_yum_rm_repo_files:
  cmd.run:
    - name: rm -f /etc/yum.repos.d/{scidb3rdparty,scidb,paradigm4,p4}.repo


