# Completely ignore non-RHEL-like systems at this time


# convert minion fqdn to scidbNameAddr
{% set clusterName  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']  %}
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']  %}

{% set scidbNetwork = pillar['scidb_cluster_info'][clusterName]['scidbNetwork'] %}
{% set scidbNetMask = pillar['scidb_cluster_info'][clusterName]['scidbNetMask'] %}
{% set scidbNameAddr= pillar['scidb_cluster_info'][clusterName]['hosts'][serverNumber]['scidbNameAddr'] %}
{% set scidbDevice  = pillar['scidb_cluster_info'][clusterName]['hosts'][serverNumber]['scidbDevice'] %}

{% set scidbIPAddr  = salt['dnsutil.A'](scidbNameAddr)[0] %}  # returns a list

# DEBUG TIP: show_full_context()


# scidbHWADDR - check on HWADDR=
# scidbUUID - optional check on UUID

#   matching/checking might look at the existing
#     

# determine if scidbName/scidbDevice is "primary"
# NOTE: could add other checks and looking at existing values listed above
#       as secondary check

{% if True or scidbIPAddr != grains['fqdn_ip4'][0] %} 

# scidbDevice -- enable if matching and not controlled by some other tool
#
# todo: might need to put the jinja if here
#       so its only if its a secondary?
scidb_ifcfg_onboot:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "ONBOOT=.*"
    - repl:    "ONBOOT='yes'"
    - append_if_not_found: True

scidb_ifcfg_network:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "NETWORK=.*"
    - repl:    {{ "NETWORK=" + scidbNetwork }}
    - append_if_not_found: True
    - require:
      - file: scidb_ifcfg_onboot

scidb_ifcfg_netmask:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "NETMASK=.*"
    - repl:    {{ "NETMASK=" + scidbNetMask }}
    - append_if_not_found: True
    - require:
      - file: scidb_ifcfg_network

scidb_ifcfg_ipaddr:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "IPADDR=.*"
    - repl:    {{ "IPADDR=" + scidbIPAddr }}
    - append_if_not_found: True
    - require: 
      - file: scidb_ifcfg_netmask

scidb_ifcfg_userctl:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "USERCTL=.*"
    - repl:    USERCTL="no"
    - append_if_not_found: True
    - require:
      - file: scidb_ifcfg_ipaddr

scidb_ifcfg_not_nm_controlled:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "NM_CONTROLLED=.*"
    - repl: "NM_CONTROLLED=no"
    - append_if_not_found: True
    - require:
      - file: scidb_ifcfg_userctl

scidb_ifcfg:
  cmd.run:
    - user: root
    - name: {{ 'ip link set dev ' + scidbDevice + ' up' }}
    - require:
      - file: scidb_ifcfg_not_nm_controlled

{% endif %}




