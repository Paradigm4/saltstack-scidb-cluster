#!py
#
# Modify pillar values for the postgres function.
# The pillar file is postgres_pillar.sls (in /srv/pillar).
# The comments are also from that pillar file.
#
def run():
    config = {}
    #
    # This section covers ACL management in the ``pg_hba.conf`` file.
    # acls list controls: which hosts are allowed to connect, how clients
    # are authenticated, which PostgreSQL user names they can use, which
    # databases they can access. Records take one of these forms:
    #
    #acls:
    #  - ['local', 'DATABASE',  'USER',  'METHOD']
    #  - ['host', 'DATABASE',  'USER',  'ADDRESS', 'METHOD']
    #  - ['hostssl', 'DATABASE', 'USER', 'ADDRESS', 'METHOD']
    #  - ['hostnossl', 'DATABASE', 'USER', 'ADDRESS', 'METHOD']
    #
    # The uppercase items must be replaced by actual values.
    # METHOD could be omitted, 'md5' will be appended by default.
    #
    # If ``acls`` item value is empty ('', [], null), then the contents of
    # ``pg_hba.conf`` file will not be touched at all.
    #
    # The last line of the pg_hba.conf file has the postgresListenerCIDR network added.
    #
    cluster_name = __pillar__['scidb_minion_info'][__grains__['fqdn']]['clusterName']
    pg_listen_cidr = __pillar__['scidb_cluster_info'][cluster_name]['postgresListenerCIDR']
    __pillar__['postgres']['acls'].append(['host',  'all', 'all', pg_listen_cidr, 'md5'])

    return config
