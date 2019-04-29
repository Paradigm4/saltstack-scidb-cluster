## JHM: modeled after the saltstack formula for epel,
## see https://github.com/saltstack-formulas/epel-formula/blob/master/epel/init.sls

{% from 'idioms.sls' import VER %}
{% from 'idioms.sls' import REPO_CREDS, REPO_SCHEME, REPO_KEY, REPO_KEY_HASH, REPO_RPM, REPO_PKGNAME %}

# TODO: eliminate defaults ... use the pillar or the local, but not both

# get the key
# TODO: add option to make wget do --no-check-certificate if possible?
{% set REPO_KEY_URI = REPO_SCHEME + '//' + REPO_CREDS + REPO_KEY %}
paradigm4_install_pubkey:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY-P4
    - source: {{ REPO_KEY_URI }}
    - source_hash: {{ REPO_KEY_HASH }}

{% set REPO_RPM_URI = REPO_SCHEME + '//' + REPO_CREDS + REPO_RPM %}
paradigm4_repo:
  pkg.installed:
    - sources:
      - {{ REPO_PKGNAME }}: {{ REPO_RPM_URI }}

paradigm4_repo_set_password:
  file.replace:
    - name: /etc/yum.repos.d/paradigm4.repo
    - flags: 'MULTILINE'
    - pattern:    '://downloads'
    - repl:    {{ '://' + REPO_CREDS + 'downloads' }}
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
# this is based on how epel-formula does it, why it defines two different state names is as yet unknown
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
