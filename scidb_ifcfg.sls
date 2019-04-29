# Completely ignore non-RHEL-like systems at this time


# convert minion fqdn to scidbNameAddr
{% set clusterName  = pillar['scidb_minion_info'][grains['fqdn']]['clusterName']  %}
{% set serverNumber = pillar['scidb_minion_info'][grains['fqdn']]['serverNumber']  %}

{% set scidbNetwork = pillar['scidb_cluster_info'][clusterName]['scidbNetwork'] %}
{% set scidbNetMask = pillar['scidb_cluster_info'][clusterName]['scidbNetMask'] %}
{% set scidbNameAddr= pillar['scidb_cluster_info'][clusterName]['hosts'][serverNumber]['scidbNameAddr'] %}
{% set scidbDevice  = pillar['scidb_cluster_info'][clusterName]['hosts'][serverNumber]['scidbDevice'] %}

{% set minionIPAddr = salt['dnsutil.A'](grains['fqdn'])[0] %}  {# returns a list #}
#DEBUG {{ 'scidbNameAddr is ' + scidbNameAddr }}

{% set scidbIPAddr  = salt['dnsutil.A'](scidbNameAddr) [0] %}  {# returns a list #}
#DEBUG {{ 'scidbIPAddr is ' + scidbIPAddr }}


# DEBUG TIP: show_full_context()


# scidbHWADDR - check on HWADDR=
# scidbUUID - optional check on UUID

#   matching/checking might look at the existing
#     

#
# determine if scidbName/scidbDevice is "primary"
#
# seems to be working.  should be true for msg1, eth1
#
# scidbDevice -- enable if scidb HBA is secondary (not matching the fqdn ip)
#
{% if scidbIPAddr != grains['fqdn_ip4'][0] %}   # fqdn_ip4 will be empty if fqdn is not a DNS name
                                                # and so this implies we are on a secondary network
                                                # and need to configure the network scripts

scidb_ifcfg_exists: 
  file.exists:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}

{% if False %}
# debugs for the test above
scidb_ifcfg_debug_fqdn_ip4: 
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern:    "fqdn_ip4=.*"
    - repl:    {{ "fqdn_ip4=" + grains['fqdn_ip4'][0] }}
    - append_if_not_found: True
    - backup: False
    - require:
      - file: scidb_ifcfg_exists

scidb_ifcfg_debug_scidbIPAddr: 
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern:    "scidbIPAddr=.*"
    - repl:    {{ "scidbIPAddr=" + scidbIPAddr }}
    - append_if_not_found: True
    - backup: False
    - require:
      - file: scidb_ifcfg_exists
{% endif %}


scidb_ifcfg_device:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "DEVICE=.*"
    - repl:    {{ "DEVICE=" + scidbDevice }}
    - append_if_not_found: True
    - backup: False
    - require:
      - file: scidb_ifcfg_exists

scidb_ifcfg_onboot:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "ONBOOT=.*"
    - repl:    "ONBOOT='yes'"
    - append_if_not_found: True
    - backup: False
    - require:
      - file: scidb_ifcfg_exists

scidb_ifcfg_network:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "NETWORK=.*"
    - repl:    {{ "NETWORK=" + scidbNetwork }}
    - append_if_not_found: True
    - backup: False
    - require:
      - file: scidb_ifcfg_onboot

scidb_ifcfg_netmask:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "NETMASK=.*"
    - repl:    {{ "NETMASK=" + scidbNetMask }}
    - append_if_not_found: True
    - backup: False
    - require:
      - file: scidb_ifcfg_network

scidb_ifcfg_ipaddr:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "IPADDR=.*"
    - repl:    {{ "IPADDR=" + scidbIPAddr }}
    - append_if_not_found: True
    - backup: False
    - require: 
      - file: scidb_ifcfg_netmask

scidb_ifcfg_userctl:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "USERCTL=.*"
    - repl:    USERCTL="no"
    - append_if_not_found: True
    - backup: False
    - require:
      - file: scidb_ifcfg_ipaddr

scidb_ifcfg_not_nm_controlled:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "NM_CONTROLLED=.*"
    - repl: "NM_CONTROLLED=no"
    - append_if_not_found: True
    - backup: False
    - require:
      - file: scidb_ifcfg_userctl

scidb_ifcfg_not_dhcp:
  file.replace:
    - name: {{ '/etc/sysconfig/network-scripts/ifcfg-' + scidbDevice }}
    - pattern: "BOOTPROTO=.*"
    - repl: "BOOTPROTO=none"
    - append_if_not_found: True
    - backup: False
    - require:
      - file: scidb_ifcfg_not_nm_controlled

scidb_ifcfg_down:
  cmd.run:
    - runas: root
    - name: {{ 'ifdown '  + scidbDevice }}
    - require:
      - file: scidb_ifcfg_not_dhcp

scidb_ifcfg_down_wait:
  cmd.run:
    - name: sleep 2
    - require:
      - cmd: scidb_ifcfg_down

scidb_ifcfg_up:
  cmd.run:
    - runas: root
    - name: {{ 'ifup ' + scidbDevice }}
    - require:
      - cmd: scidb_ifcfg_down

scidb_ifcfg_up_wait:
  cmd.run:
    - name: sleep 4
    - require:
      - cmd: scidb_ifcfg_up

scidb_ifcfg:
  cmd.run:
    - runas: root
    - name: ip addr
    - require:
      - cmd: scidb_ifcfg_up_wait

{% else %}
scidb_ifcfg:                            # externally referenced
  cmd.run:
    - name: /bin/true
{% endif %}
