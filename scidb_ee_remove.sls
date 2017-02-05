# scidb_ee_remove.sls

scidb_ee_remove_yum_rm_repo_files:
  cmd.run:
    - name: rm -f /etc/yum.repos.d/{scidb,paradigm4,p4}.repo

scidb_ee_remove_yum_erase_paradigm4_pkgs:
  cmd.run:
    - name: yum list | grep paradigm4 | awk '{print $1}' | grep '[a-zA-Z]' | xargs rpm -e

scidb_ee_remove_yum_erase_scidb_pkgs:
  cmd.run:
    - name: yum list | grep scidb | awk '{print $1}' | grep '[a-zA-Z]' | xargs rpm -e

scidb_ee_remove_yum_clean_all:
  cmd.run:
    - name: yum clean all

