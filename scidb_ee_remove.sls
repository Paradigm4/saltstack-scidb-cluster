# scidb_ee_remove.sls

scidb_ee_remove_yum_clean_all:
  cmd.run:
    - name: yum --enablerepo=paradigm4 clean all

scidb_ee_remove_yum_clean_metadata:
  cmd.run:
    - name: yum --enablerepo=paradigm4 clean metadata

scidb_ee_remove_yum_erase_paradigm4_pkgs:
  cmd.run:
    # yum -y remove was rpm -e
    - name: yum list | grep -i paradigm4 | awk '{print $1}' | grep '[a-zA-Z]' | xargs yum -y remove

scidb_ee_remove_yum_erase_scidb_pkgs:
  cmd.run:
    # yum -y remove was rpm -e
    - name: yum list | grep -i scidb | awk '{print $1}' | grep '[a-zA-Z]' | xargs yum -y remove


scidb_ee_remove_yum_rm_repo_files:
  cmd.run:
    - name: rm -f /etc/yum.repos.d/{scidb,paradigm4,p4}.repo


