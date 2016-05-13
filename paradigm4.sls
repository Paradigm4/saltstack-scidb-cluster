## JHM: modeled after the saltstack formula for epel,
## see https://github.com/saltstack-formulas/epel-formula/blob/master/epel/init.sls

## Completely ignore non-RHEL-like systems at this time

# TODO: become a lookup table for scidb GPG keys & RPM URLs for various releases
{% set credential = pillar['paradigm4_repo_credential'] %}
{% set locals = {
'key'      : 'https://downloads.paradigm4.com/key',
'key_hash' :'md5=2f90272e0230804262e334e654067d7b',
'rpm'      : 'https://' + credential + '@downloads.paradigm4.com/enterprise/15.12/centos6.3/paradigm4-repo-15-12.noarch.rpm',
} %}
# note: generated the md5 by doing a wget of the key and the doing md5sum on it

# TODO: eliminate defaults ... use the pillar or the local, but not both

install_pubkey_paradigm4:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY-P4
    - source: {{ locals.key }}
    - source_hash: {{ locals.key_hash }}

paradigm4_repo:
  pkg.installed:
    - sources:
      - paradigm4-repo: {{ locals.rpm }}
    - require:
      - file: install_pubkey_paradigm4

set_password_paradigm4_repo:
  file.replace:
    - name: /etc/yum.repos.d/paradigm4.repo
    - pattern: 'https://[^@]*@?downloads.paradigm4.com/enterprise'  # cover any credential that might precede the path itself
    - repl:    {{ 'https://' + credential + '@downloads.paradigm4.com/enterprise' }}  # insert the credential
    - require:
      - pkg: paradigm4_repo

set_pubkey_paradigm4_repo:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/paradigm4.repo
    - pattern: '^gpgkey=.*'
    - repl: 'gpgkey=file://etc/pki/rpm-gpg/RPM-GPG-KEY-P4'
    - require:
      - pkg: paradigm4_repo
      - file: set_password_paradigm4_repo # was paradgim4_repo until password needed adding

# action to set gpgcheck on for paradigm4 repo
get_gpg_paradigm4_repo:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/paradigm4.repo
    - pattern: 'gpgcheck=.*'
    - repl: 'gpgcheck=1'
    - require:
      - pkg: paradigm4_repo

#
# enabling/disabling scidb_repo
#
# this is baded on how epel-formula does it, why it defines two different state names is as yet unknown
#

{% if salt['pillar.get']('paradigm4:disabled', False) %}
disable_paradigm4:
  file.replace:
    - name: /etc/yum.repos.d/paradigm4.repo
    - pattern: '^enabled=[0,1]'
    - repl: 'enabled=0'
{% else %}
enable_paradigm4:
  file.replace:
    - name: /etc/yum.repos.d/paradigm4.repo
    - pattern: '^enabled=[0,1]'
    - repl: 'enabled=1'
{% endif %}

