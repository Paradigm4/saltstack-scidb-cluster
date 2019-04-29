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

# determine if scidbName/scidbDevice is "primary"
# NOTE: could add other checks and looking at existing values listed above as a secondary check?

# are we using a "secondary" network for scidb?
# if so, iterate over all  ipNameAddr and add them to the hosts file

{% if scidbIPAddr != grains['fqdn_ip4'][0] %}   {# fqdn_ip4 will be empty if fqdn is not a DNS name #}
                                                {# and so this implies we are on a secondary network #}
                                                {# and need to configure the network scripts #}

  {% set HOST_NUMS  = pillar['scidb_cluster_info'][clusterName]['hostNums'] %}  {# to iterate through cluster's hosts #}
  {% for hostNum in HOST_NUMS %}
    {% set hostScidbName= pillar['scidb_cluster_info'][clusterName]['knownHostsList'][hostNum] %}
    {% set hostScidbAddr= salt['dnsutil.A'](hostScidbName)[0] %}  {# returns a list, so [0] #}

scidb_etc_hosts_extend_{{hostNum}}:
  file.replace:
    - name: /etc/hosts
    - pattern: {{hostScidbAddr +".*"}}
    - repl:    {{hostScidbAddr +" " +hostScidbName}}
    - append_if_not_found: True

  {% endfor %}
{% endif %}
