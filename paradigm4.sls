## JHM: modeled after the saltstack formula for epel,
## see https://github.com/saltstack-formulas/epel-formula/blob/master/epel/init.sls

## Completely ignore non-RHEL-like systems at this time
{% set CRED     = pillar['p4repo_creds'] %}  # user:password@
{% set REPO     = pillar['p4repo'] %}
{% set KEY_HASH = pillar['p4repo_gpg_key_hash'] %}
{% set VER      = pillar['scidb_ver'] %}


# TODO: eliminate defaults ... use the pillar or the local, but not both

install_pubkey_paradigm4:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY-P4
    - source_hash: {{ KEY_HASH }}
    - source: {{ REPO + '/key' }}
    - TODO: add option to make wget do --no-check-certificate

{% set REPO_URI = pillar['p4repo_scheme'] + '//' + CRED + REPO %}
paradigm4_repo:
  pkg.installed:
    - sources:
      - paradigm4-repo: {{ REPO_URI }}
    - require:
      - file: install_pubkey_paradigm4

set_password_paradigm4_repo:
  file.replace:
    - name: /etc/yum.repos.d/paradigm4.repo
    - pattern: '//[^@]*@?downloads'  # regex must match an optional credential like xx:yy@
    - repl:    {{ '//' + CRED + 'downloads' }}
    - require:
      - pkg: paradigm4_repo

set_pubkey_paradigm4_repo:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/paradigm4.repo
    - pattern: '^gpgkey=.*'
    - repl: 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-P4'
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

