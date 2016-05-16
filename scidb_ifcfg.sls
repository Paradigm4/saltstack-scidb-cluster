# Completely ignore non-RHEL-like systems at this time


# convert minion fqdn to scidbNameAddr
{% set clusterName  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']  %}
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']  %}

{% set scidbNetwork = pillar['scidb_cluster_info'][clusterName]['scidbNetwork'] %}
{% set scidbNetMask = pillar['scidb_cluster_info'][clusterName]['scidbNetMask'] %}
{% set scidbNameAddr= pillar['scidb_cluster_info'][clusterName]['hosts'][serverNumber]['scidbNameAddr'] %}
{% set scidbDevice  = pillar['scidb_cluster_info'][clusterName]['hosts'][serverNumber]['scidbDevice'] %}

{% set minionIPAddr = salt['dnsutil.A'](grains['fqdn'])[0] %}  # returns a list
#DEBUG {{ 'scidbNameAddr is ' + scidbNameAddr }}

{% set scidbIPAddr  = salt['dnsutil.A'](scidbNameAddr) [0] %}  # returns a list
#DEBUG {{ 'scidbIPAddr is ' + scidbIPAddr }}


# DEBUG TIP: show_full_context()


# scidbHWADDR - check on HWADDR=
# scidbUUID - optional check on UUID

#   matching/checking might look at the existing
#     

# determine if scidbName/scidbDevice is "primary"
# NOTE: could add other checks and looking at existing values listed above
#       as secondary check

{% if scidbIPAddr != grains['fqdn_ip4'][0] %}   # fqdn_ip4 will be empty if fqdn is not a DNS name
                                                # and fqdn is really just minion name so can be
                                                # overridden by /etc/salt/minion_id to not be an fqdn
                                                # known to DNS, by accident

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

scidb_ifcfg_not_dhcp:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "BOOTPROTO=.*"
    - repl: "BOOTPROTO=none"
    - append_if_not_found: True
    - require:
      - file: scidb_ifcfg_not_nm_controlled

scidb_ifcfg_down:
  cmd.run:
    - user: root
    - name: {{ 'ifdown '  + scidbDevice }}
    - require:
      - file: scidb_ifcfg_not_dhcp

scidb_ifcfg:
  cmd.run:
    - user: root
    - name: {{ 'ifup ' + scidbDevice }}
    - require:
      - cmd: scidb_ifcfg_down

{% endif %}




