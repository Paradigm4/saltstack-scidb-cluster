{% from 'idioms.sls' import VER %}
{% from 'idioms.sls' import REPO_URL, REPO_KEY %}

{% if VER > "18.2" %}
{% else %}
scidb3rdparty:
  pkgrepo.managed:
  - name: scidb3rdparty
  - humanname: SciDB 3rdparty repository
{% if grains['osmajorrelease'] == 6 %}
  - baseurl: https://downloads.paradigm4.com/centos6.3/3rdparty
{% elif grains['osmajorrelease'] == 7 %}
  - baseurl: https://downloads.paradigm4.com/centos7/3rdparty
{% endif %}
  - key_url: https://downloads.paradigm4.com/RPM-GPG-KEY-scidb
## JHM: modeled after the saltstack formula for epel,
## see https://github.com/saltstack-formulas/epel-formula/blob/master/epel/init.sls

paradigm4:
  pkgrepo.managed:
  - name: paradigm4
  - humanname: Paradigm4 repository
  - baseurl: {{ REPO_URL }}
  - key_url: {{ REPO_KEY }}
  - gpgcheck: 1
  - enabled: 1
{% endif %}
