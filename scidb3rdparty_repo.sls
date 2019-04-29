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
