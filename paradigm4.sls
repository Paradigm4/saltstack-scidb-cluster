## JHM: modeled after the saltstack formula for epel,
## see https://github.com/saltstack-formulas/epel-formula/blob/master/epel/init.sls

## Completely ignore non-RHEL-like systems at this time
{% set CREDS         = pillar['p4repo_creds'] %}
{% set REPO_KEY      = pillar['p4repo_key'] %}
{% set REPO_KEY_HASH = pillar['p4repo_key_hash'] %}
{% set REPO_RPM      = pillar['p4repo_rpm'] %}
{% set VER           = pillar['scidb_ver'] %}

# TODO: eliminate defaults ... use the pillar or the local, but not both

# get the key
# TODO: add option to make wget do --no-check-certificate if possible?
{% set REPO_KEY_URI = pillar['p4repo_scheme'] + '//' + CREDS + REPO_KEY %}
paradigm4_install_pubkey:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY-P4
    - source: {{ REPO_KEY_URI }}
    - source_hash: {{ REPO_KEY_HASH }}

{% set REPO_RPM_URI = pillar['p4repo_scheme'] + '//' + CREDS + REPO_RPM %}
paradigm4_repo:
  pkg.installed:
    - sources:
      - paradigm4-repo: {{ REPO_RPM_URI }}

paradigm4_repo_set_password:
  file.replace:
    - name: /etc/yum.repos.d/paradigm4.repo
    - flags: 'MULTILINE'
    - pattern:    '://downloads'
    - repl:    {{ '://' + CREDS + 'downloads' }}
    - count: 2                                    # baseurl=, gpgkey=

paradigm4_repo_set_pubkey:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/paradigm4.repo
    - pattern: '^gpgkey=.*'
    - repl: 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-P4'

# action to set gpgcheck on for paradigm4 repo
paradigm4_repo_get_gpg:
  file.replace:
    - append_if_not_found: True
    - name: /etc/yum.repos.d/paradigm4.repo
    - pattern: 'gpgcheck=.*'
    - repl: 'gpgcheck=1'

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
