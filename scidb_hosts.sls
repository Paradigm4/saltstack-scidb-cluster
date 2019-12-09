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

# Definitions
#   A primary network is the administrative network by which salt can always reach the test machines to configure them.
#   A secondary network is the network to be used when configuring scidb, for scidb communications (intra machine communication).
#   This is likely to be a private network not connected to the primary network.
#
# We need to determine if scidbName/scidbDevice is on the primary or secondary network.
# If it is on the primary network then the device is already configured, may be in the /etc/hosts file, and is DNS lookup-able.
# If it is on a secondary network then we need to add the IP of the card to the /etc/hosts file.
#
# Iterate over all the ipNameAddr of the network adapters on the secondary network
# and add them to the hosts file.

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
