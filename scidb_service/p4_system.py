#!/usr/bin/python
#
# BEGIN_COPYRIGHT
#
# PARADIGM4 INC.
# This file is part of the Paradigm4 Enterprise SciDB distribution kit
# and may only be used with a valid Paradigm4 contract and in accord
# with the terms and conditions specified by that contract.
#
# Copyright (C) 2010 - 2015 Paradigm4 Inc.
# All Rights Reserved.
#
# END_COPYRIGHT
#

# Python module for scidb.py providing
# SciDB Linux SysV service administration/configuration

import sys
import time
import os
from ConfigParser import RawConfigParser
from ConfigParser import SafeConfigParser
import argparse
import traceback
import functools
import bisect
import scidb

from scidblib import AppError

scidb._PGM = "p4_system:"       # used by scidb.printError()

class P4CmdExecutor(scidb.CmdExecutor):
    def __init__(self, ctx):
       """
       This is the entry class for the p4_system scidb.py plugin.
       It supports the Linux SysV configuration functionality for SciDB as
       well as such operation as cluster reconfiguration (e.g. adding/removing instances.
       """
       scidb.CmdExecutor.__init__(self,ctx)

    def waitToStart(self, servers, procNum, errorStr, instances=None, maxAttempts=10):
       """
       Wait for the specified (or all) SciDB instances to be started on a given list of servers.
       An instance is considered started when 2 OS processes with the same command line
       are found by the ps command.
       The command line must be of the form:
       <base_path>/<server_id>/<server_instance_id>/SciDB-<server_id>-<server_instance_id>
       """
       attempts=0
       conns = []
       try:
           conns = [scidb.sshconnect(srv) for srv in servers]
           pidCount = scidb.check_scidb_running(sshConns=conns,servers=servers,instances=instances)
           while pidCount < procNum:
               attempts += 1
               if attempts>maxAttempts:
                   raise AppError(errorStr)
               time.sleep(1)
               pidCount = scidb.check_scidb_running(sshConns=conns,servers=servers,instances=instances)
       finally:
           scidb.sshCloseNoError(conns)

    def start_server(self):
       """
       Start some/all the instances on a given SciDB server
       """
       instances = None
       if self._ctx._args.all:
          serversToStart = self._ctx._srvList
          errStr = "on %d servers"%(len(serversToStart))
          if self._ctx._args.instance_filter:
             raise AppError("Instance filter is not allowed with --all")
       elif self._ctx._args.server_id:
          srvId = self.findServerIndex(int(self._ctx._args.server_id))
          serversToStart = [ self._ctx._srvList[srvId] ]
          errStr = "on server %d"%(srvId)
          if self._ctx._args.instance_filter: #always need instances to support multiple servers/host
              instanceRanges = self._ctx._args.instance_filter.split(',')
              instances = [ scidb.parseServerInstanceIds(instanceRanges)  ]
       else:
          raise AppError("Invalid server ID specification")

       if instances:
           numberOfProcs=len(instances[0]) * 2 #XXX +1 for watchdog
       else:
           instances = scidb.applyInstanceFilter(serversToStart, instances, nonesOK=False)
           numberOfProcs = scidb.getInstanceCount(serversToStart) * 2 #XXX +1 for watchdog

       scidb.startSomeServers(serversToStart, instances=instances)
       errStr = "Failed to start SciDB %s"%(errStr)
       self.waitToStart(serversToStart, numberOfProcs, errStr, instances=instances)

    def stop_server(self):
       """
       Stop some/all the instances on a given SciDB server
       """
       instances = None
       if self._ctx._args.all:
          serversToStop = self._ctx._srvList
          errStr = "on %d servers"%(len(serversToStop))
          if self._ctx._args.instance_filter:
             raise AppError("Instance filter is not allowed with --all")
       elif self._ctx._args.server_id:
          srvId = self.findServerIndex(int(self._ctx._args.server_id))
          serversToStop = [ self._ctx._srvList[srvId] ]
          errStr = "on server %d"%(srvId)
          if self._ctx._args.instance_filter: #always need instances to support multiple servers/host
              instanceRanges = self._ctx._args.instance_filter.split(',')
              instances = [ scidb.parseServerInstanceIds(instanceRanges)  ]
          else:
              instances = scidb.applyInstanceFilter(serversToStop, instances, nonesOK=False)
       else:
          raise AppError("Invalid server ID specification")

       errStr = "Failed to stop SciDB %s"%(errStr)

       scidb.stopSomeServers(serversToStop, instances=instances)
       self.waitToStop(serversToStop, errStr, instances=instances)

    def config_server(self):
        """
        Re/configure instances on one or more servers in accordance with a user-specified file.
        """
        if self._ctx._args.add_delta:
            self.addServer(self._ctx._args.add_delta, force=self._ctx._args.force)
        elif self._ctx._args.remove_delta:
            self.removeServer(self._ctx._args.remove_delta, force=self._ctx._args.force)
        else:
            assert False, "Unreachable code!"

    def addServer(self, deltaFile, force):
        """
        Add instances on one or more servers in accordance with a user-specified file.
        """
        deltaCtx = scidb.Context()
        deltaCtx._scidb_name = self._ctx._scidb_name
        deltaCtx._config_file = deltaFile
        scidb.parseConfig(deltaCtx)

        self.validateConfigForAddDelta(deltaCtx)

        numInstances = 0
        # merge server-id's while detecting duplicates
        for deltaSrv in deltaCtx._srvList:
            i = bisect.bisect_left(self._ctx._srvList, deltaSrv) #binary search
            if i != len(self._ctx._srvList) and \
               self._ctx._srvList[i].getServerId() == deltaSrv.getServerId():
               self._ctx._srvList[i].addInstances(deltaSrv)
            else:
                numInstances = numInstances + len(deltaSrv.getServerInstances())

        numInstances = numInstances + scidb.getInstanceCount(self._ctx._srvList)

        config = self.addDeltaToConfig(deltaCtx)

        # write out the new config file
        self.depositConfigFile(self._ctx._args.output, config)

        try:
            scidb.checkMaxPostgresConns(numInstances)
        except Exception as pgException:
            if not force:
                raise AppError("Postgres exception: %s" % pgException)
            printWarn(pgException)

        scidb.checkRedundancy(numInstances)

        # try to register the instances
        # the operation may partially succeed/fail
        scidb.initSomeInParallel(deltaCtx._srvList, instances=None,
                                 force=force, remove=force,
                                 initialize=False, online="infinity")


    def addDeltaToConfig(self, deltaCtx):
       config = SafeConfigParser()
       # from python doc:
       # When adding sections or items, add them in the reverse order of
       # how you want them to be displayed in the actual file.
       # In addition, please note that using RawConfigParser's and the raw
       # mode of ConfigParser's respective set functions, you can assign
       # non-string values to keys internally, but will receive an error
       # when attempting to write to a file or when you get it in non-raw
       # mode. SafeConfigParser does not allow such assignments to take place.
       config.add_section(self._ctx._scidb_name)

       # add the new opts
       for key,value in deltaCtx._configOpts.iteritems():
           config.set(self._ctx._scidb_name, key, str(value))

       # add the old opts
       for key,value in self._ctx._configOpts.iteritems():
           if key != "db_passwd" :
               config.set(self._ctx._scidb_name, key, str(value))

       # override the merged entries
       for srv in self._ctx._srvList:
           key,value = srv.toConfigOpt()
           config.set(self._ctx._scidb_name, key, str(value))

       return config

    def depositConfigFile(self, fileName, config):
       file = None
       try:
           if fileName == '-':
               file = sys.stdout
           else:
               file = open(fileName, 'w')
           config.write(file)
           file.close()
           file = None
       finally:
           try:
               if file: file.close()
           except: pass

    def validateConfigForAddDelta(self, deltaCtx):
        numSrvs = 0
        numPrefixes = 0
        for key in deltaCtx._configOpts.iterkeys():
            if 'server-' in key:
                numSrvs += 1
            elif 'data-dir-prefix-' in key:
                if key in self._ctx._configOpts:
                    raise AppError("Option %s already exists"%(key))
                numPrefixes += 1
                self._ctx._configOpts[key] = deltaCtx._configOpts[key]
            elif key == 'db_name':
                assert deltaCtx._configOpts[key] == self._ctx._scidb_name, \
                    "Unexpected SciDB name %s" % (str(deltaCtx._configOpts[key]))
            else:
                raise AppError("Unknown option with key %s"%(key))

        assert numSrvs == len(deltaCtx._srvList), "Duplicate server- entries"

        numMatched = 0
        for deltaSrv in deltaCtx._srvList:
            for liid in deltaSrv.getServerInstances():
               if 'data-dir-prefix-%d-%d' % (deltaSrv.getServerId(),liid) in deltaCtx._configOpts:
                   numMatched += 1
        if numPrefixes != numMatched:
            raise AppError("Duplicate/invalid data-dir-prefix entries")

    def validateConfigForRemoveDelta(self, deltaCtx):
        numSrvs = 0
        for key in deltaCtx._configOpts.iterkeys():
            if 'server-' in key:
                numSrvs += 1
            elif key == 'db_name':
                assert deltaCtx._configOpts[key] == self._ctx._scidb_name, \
                    "Unexpected SciDB name %s" % (str(deltaCtx._configOpts[key]))
            else:
                raise AppError("Unknown option with key %s"%(key))

        assert numSrvs == len(deltaCtx._srvList), "Duplicate server- entries"

    def removeServer(self, deltaFile, force):
        """
        Remove instances on one or more servers in accordance with a user-specified file.
        """
        deltaCtx = scidb.Context()
        deltaCtx._scidb_name = self._ctx._scidb_name
        deltaCtx._config_file = deltaFile
        scidb.parseConfig(deltaCtx)

        self.validateConfigForRemoveDelta(deltaCtx)

        # weed out the server-id's
        for deltaSrv in deltaCtx._srvList:
            i = bisect.bisect_left(self._ctx._srvList, deltaSrv) #binary search
            if i != len(self._ctx._srvList) and \
               self._ctx._srvList[i].getServerId() == deltaSrv.getServerId():
               self._ctx._srvList[i].removeInstances(deltaSrv)

               if self._ctx._srvList[i].getServerInstances(): pass
               elif self._ctx._srvList[i].getServerHost() == self._ctx.pgHost:
                  raise AppError("Cannot remove all instances from the host with "+
                                 "the system catalog postgres instance %s" % self._ctx.pgHost)
               self.removeDataDirPrefixes(deltaSrv)
            else:
                raise AppError("Cannot remove non-existent server %s" % (str(deltaSrv)))

        newSrvList = [srv for srv in self._ctx._srvList if srv.getServerInstances() ]
        if not newSrvList:
            raise AppError("Cannot remove all instances")
        self._ctx._srvList = newSrvList

        scidb.checkRedundancy(scidb.getInstanceCount(self._ctx._srvList))

        config = self.removeDeltaFromConfig()

        ret = self.unregisterSomeServers(deltaCtx._srvList, force=force)
        assert ret, "Unexpected failure in while unregistering!"

        self.depositConfigFile(self._ctx._args.output, config)

    def removeDataDirPrefixes(self, deltaSrv):
        for liid in deltaSrv.getServerInstances():
            self._ctx._configOpts.pop('data-dir-prefix-%d-%d' % (deltaSrv.getServerId(),liid), '')

    def checkDirs(self, servers):
        '''
        Check if the data paths for a given list of instances exist.
        @throw scidb.RemoteAppError if the direcotry does not exist
        '''
        def generateCheckDirCmds(servers,conns):
            cmds=[]
            for srv in servers:
                cmdList = []
                for liid in srv.getServerInstances():
                    ldir = scidb.getInstanceDataPath(srv, liid)

                    iCmd = ' '.join(['ls', '-dl', ldir+'/', '1>/dev/null'])
                    cmdList.append(iCmd)
                cmds.append(' && '.join(cmdList))

            return cmds
        func = generateCheckDirCmds
        scidb.printInfo("Checking instance directories ...")
        self.runRemote(servers, func, "Check instance directories")


    def removeDeltaFromConfig(self):
       config = SafeConfigParser()
       # from python doc:
       # When adding sections or items, add them in the reverse order of
       # how you want them to be displayed in the actual file.
       # In addition, please note that using RawConfigParser's and the raw
       # mode of ConfigParser's respective set functions, you can assign
       # non-string values to keys internally, but will receive an error
       # when attempting to write to a file or when you get it in non-raw
       # mode. SafeConfigParser does not allow such assignments to take place.
       config.add_section(self._ctx._scidb_name)

       # add the old opts except server-
       for key,value in self._ctx._configOpts.iteritems():
           if "server-" in key or key == "db_passwd" :
               continue
           config.set(self._ctx._scidb_name, str(key), str(value))

       # add the new list of server-
       for srv in self._ctx._srvList:
           key,value = srv.toConfigOpt()
           config.set(self._ctx._scidb_name, key, str(value))

       return config


    def unregisterSomeServers(self, deltaSrvs, force):
        """
        Unregister the instances on the specified servers from SciDB
        using the unregister_instances() operator
        @param deltaSrvs the servers whose instances to be unregistered
        @param force if set the existence of data directories is not checked
        and the absence of the specified instances in SciDB is ignored.
        If unset, the above conditions will cause an exception
        @throw scidblib.AppError
        """
        if not force:
            self.checkDirs(deltaSrvs)

        coordinator = self._ctx._srvList[0] #coordinator

        iqueryPrefix = [ self._ctx._installPath + "/bin/iquery"]
        if self._ctx._args.auth_file:
            iqueryPrefix.extend(['--auth-file', self._ctx._args.auth_file])

        iid = coordinator.getServerInstances()[0]

        scidb.printDebug("Coordinator srv: %s" % str(coordinator))
        scidb.printDebug("Coordinator instance %s" % str(iid))

        iqueryPrefix.extend ([
                "-c"
                , coordinator.getServerHost()
                , "-p"
                , str(self._ctx._basePort + iid)
                ])
        iqueryPrefix.extend([ "-o", 'csv'])

        cmdList = [i for i in iqueryPrefix]
        cmdList.extend(["-aq", "\"project(list_instances(), server_id, server_instance_id, instance_id);\"" ])

        (ret,out,err) = scidb.executeLocal(cmdList,
                                           None,
                                           nocwd=True,
                                           useConnstr=False,
                                           ignoreError=False,
                                           useShell=True,
                                           sout=os.tmpfile())

        assert ret==0, "Unexpected error from: %s " % str(cmdList)

        scidb.printDebug("Instances: %s" % out)

        lines = out.splitlines()
        out=None
        parsedIds = {}
        def parseLine(line):
            ids = line.lstrip().rstrip().split(',')
            if len(ids) < 3:
                raise AppError("Unexpected instance [server_id,server_instance_id,instance_id]: %s " % (ids))
            parsedIds[','.join(ids[0:2])] = int(ids[2])
        map(parseLine, lines)

        scidb.printDebug("Parsed IDs: %s " % str(parsedIds))

        instance_ids = []
        for srv in deltaSrvs:
            for liid in srv.getServerInstances():
                key = ','.join([str(srv.getServerId()), str(liid)])
                if key in parsedIds:
                    instance_ids.append(parsedIds[key])
                else:
                    msg = "Unknown instance: %s " % (scidb.validateInstance(srv, liid))
                    if force:
                        scidb.printWarn(msg)
                    else:
                        raise AppError(msg)
        ret = 0
        if len(instance_ids) > 0:
            cmdList = [i for i in iqueryPrefix]
            cmdList.extend(["-naq", "\"unregister_instances(%s);\"" % (",".join(map(str, instance_ids)))])
            (ret,out,err) = scidb.executeLocal(cmdList,
                                               None,
                                               nocwd=True,
                                               useConnstr=False,
                                               ignoreError=False,
                                               useShell=True)
        elif not force:
            raise AppError("No instances to unregister")
        return (ret==0)

    def status_server(self):
       """
       Check if the servers specified in the config file are up.
       """
       if self._ctx._args.all:
          serversToCheck = self._ctx._srvList
          errStr = "on %d servers"%(len(serversToCheck))
       elif self._ctx._args.server_id:
          srvId = self.findServerIndex(int(self._ctx._args.server_id))
          serversToCheck = [ self._ctx._srvList[srvId] ]
          errStr = "on server %d"%(srvId)
       else:
          raise AppError("Invalid server ID specification")

       numberOfProcs = scidb.getInstanceCount(serversToCheck) * 2 #XXX make sure watchdog is on

       errStr = "Failed to find %d SciDB processes %s"%(numberOfProcs,errStr)
       #always need instances to support multiple servers/host
       instances = None
       instances = scidb.applyInstanceFilter(serversToCheck, instances, nonesOK=False)
       self.waitToStart(serversToCheck, numberOfProcs, errStr, maxAttempts=2, instances=instances)

    def service_add(self):
       """
       Add SciDB-<version> service to the SysV metadata (i.e. create /etc/init.d/SciDB-<version> script)
       """
       self.addService(self._ctx._args.user)

    def service_remove(self):
       """
       Remove SciDB-<version> service to the SysV metadata (i.e. create /etc/init.d/SciDB-<version> script)
       """
       self.removeService(force=self._ctx._args.force)

    def service_register(self):
       """
       Register new SciDB database cluster with the SciDB-<version> SysV service
       on the servers specified in a config.ini file
       """
       if self._ctx._args.all:
          serversToRegister = self._ctx._srvList
       elif self._ctx._args.server_id:
          srvId = self.findServerIndex(int(self._ctx._args.server_id))
          serversToRegister = [ self._ctx._srvList[srvId] ]
       else:
          raise AppError("Invalid server ID specification")

       self.registerSomeServices(serversToRegister)

    def service_unregister(self):
       """
       Unregister SciDB database cluster from the SciDB-<version> SysV service
       on the servers specified in a config.ini file
       """
       if self._ctx._args.all:
          serversToUnregister = self._ctx._srvList
       elif self._ctx._args.server_id:
          srvId = self.findServerIndex(int(self._ctx._args.server_id))
          serversToUnregister = [ self._ctx._srvList[srvId] ]
       else:
          raise AppError("Invalid server ID specification")

       self.unregisterSomeServices(serversToUnregister,force=self._ctx._args.force)


    def findServerIndex(self, srvId):
        """
        Find the server entry index for a given server_id in the list of servers
        specified in the config.ini
        """
        srvIdList = [ srv.getServerId() for srv in self._ctx._srvList]
        i = bisect.bisect_left(srvIdList, srvId) #binary search
        if i != len(srvIdList) and srvIdList[i] == srvId:
            return i
        raise AppError("Invalid server ID=%d"%srvId)


    def registerSomeServices(self, servers, conns=None):
       def registerSomeServicesFunc(servers,conns):
          # deposit config files
          # XXX TODO: run in parallel
          config = self.getDBConfig()
          for pair in zip(conns,servers):
             self.depositConfigDBFile(pair[0], self.getConfigDBFilename(pair[1])+".tmp", config)
          cmds = [ self.getServiceRegisterCmd(srv) for srv in servers ]
          return cmds
       func = registerSomeServicesFunc
       self.runRemote(servers, func, "register SciDB service")

    def unregisterSomeServices(self, servers, force, conns=None):
       def func(servers, conns):
          cmds = [ self.getServiceUnregisterCmd(srv,force) for srv in servers ]
          return cmds
       self.runRemote(servers, func, "unregister SciDB service")

    def addService(self, user):
       cmdList = self.getServiceAddCmd(user)
       scidb.executeLocal(cmdList,
                          None,
                          nocwd=True,
                          useConnstr=False,
                          ignoreError=False,
                          useShell=True)

    def removeService(self,force):
       cmdList = self.getServiceRemoveCmd(force)
       scidb.executeLocal(cmdList,
                          None,
                          nocwd=True,
                          useConnstr=False,
                          ignoreError=False,
                          useShell=True)

    def depositConfigDBFile(self, sshClient, remoteFile, config):
       """
       Deposit a configuration file used by the SciDB service to a remote host
       using sftp
       """
       sftp = None
       sftpFile = None
       try:
          sftp = sshClient.get_transport().open_sftp_client()
	  scidb.printDebug("@@@@ sftp remote file is: %s" % remoteFile)
          sftpFile = sftp.file(remoteFile, mode='wx') #O_EXCL
          config.write(sftpFile)
          sftpFile.close()
          sftpFile=None
          sftp.close()
          sftp=None
       finally:
          if sftpFile: scidb.sshCloseNoError([sftpFile])
          if sftp: scidb.sshCloseNoError([sftp])

    def runRemote(self, servers, func, opStr, remoteUsers=None, remotePwds=None, conns=None):
       """
       Run remote commands generate by a given functor on a list of remote servers
       """
       closeSSH = False
       if not conns:
          closeSSH = True
          cons = []

       try:
          if closeSSH:
             if not remoteUsers:
                conns = [scidb.sshconnect(srv) for srv in servers]
             else:
                conns = [scidb.sshconnect(trio[0],username=trio[1], password=trio[2])
                         for trio in zip(servers,remoteUsers,remotePwds)]

          # generate remote commands
          cmds = func(servers,conns)
          # execute
          (ret,out,err) = scidb.parallelRemoteExec(conns, cmds)
          map(lambda c: c.close(),conns)
       finally:
          if closeSSH: scidb.sshCloseNoError(conns)

       i=0
       scidb.printDebug("parallelRemoteExec out's: %s"%(str(out)))
       scidb.printDebug("parallelRemoteExec err's: %s"%(str(err)))

       for rc in ret:
          if rc != 0:
             raise AppError("Failed to %s on server %d, errors: %s" % (
                     opStr, servers[i][0], str(err)))
          i += 1

    def getConfigDBDir(self):
       configRuntimeDir = os.path.join(self._ctx._installPath, "service")
       return configRuntimeDir

    def getConfigDBFilename(self, srv):
       configRuntimeCopy = os.path.join(self.getConfigDBDir(),
                                        "config-"+str(srv.getServerId())+"-"+self._ctx._scidb_name)
       return configRuntimeCopy

    def getInitdBinNameDB(self, version, serverId, scidb_name):
       initdBinName = "SciDB-"+version+"-"+str(serverId)+"-"+scidb_name
       return initdBinName

    def getInitdBinName(self, version):
       initdBinName = "SciDB-"+version
       return initdBinName

    def getScidbVersion(self):
       cmdList=[self._ctx._installPath+"/bin/scidb", "--version"]
       (ret,out,err) = scidb.executeLocal(cmdList, None,
                                          nocwd=True,
                                          useConnstr=False,
                                          useShell=False,
                                          ignoreError=False,
                                          sout=os.tmpfile())
       version = out.strip().split("\n")[0].split(":")[1].split(".")
       version = ".".join(version[0:2]).strip()
       scidb.printDebug(" version = %s"%(version))
       return version

    def getServiceAddCmd(self, user):
       version      = self.getScidbVersion()
       initdBinSrc  = os.path.join(self._ctx._installPath, "bin", "scidb.initd")
       initdName    = self.getInitdBinName(version)
       initdBinPath = os.path.join("/etc/init.d", initdName)
       configDBDir  = self.getConfigDBDir()

       installPath = "\\\\/".join(self._ctx._installPath.split("/"))
       scidb.printDebug("installPath = %s"%(installPath))

       cmdList=["/bin/sed", "s/XXX_INSTALL_PATH_XXX/"+installPath+"/", initdBinSrc,
                "|", "/bin/sed", "s/XXX_SERVICE_USER_XXX/"+user+"/",
                "|", "/bin/sed", "s/XXX_SERVICE_NAME_XXX/"+initdName+"/",
                ">", initdBinPath]
       cmdList.extend([" && ", "/bin/chmod", "a-rwx,u+rwx,g+rx,o+rx", initdBinPath])
       cmdList.extend([" && ", "/bin/mkdir", "-p", configDBDir])
       cmdList.extend([" && ", "/bin/chown", user, configDBDir])
       #
       # On Ubuntu use update-rc.d to manage services
       # On CentOS/RedHat use chkconfig to manage services
       #
       if os.path.exists("/usr/sbin/update-rc.d"):
           cmdList.extend([" && ", "/usr/sbin/update-rc.d", initdName, "defaults"])
       else:
           cmdList.extend([" && ", "/sbin/chkconfig", "--add", initdName])
       scidb.printDebug("cmd = %s"%(str(cmdList)))
       return cmdList

    def getServiceRemoveCmd(self, force=False):
       version      = self.getScidbVersion()
       initdName    = self.getInitdBinName(version)
       initdBinPath = os.path.join("/etc/init.d", initdName)

       if force:
          sep=";"
       else:
          sep="&&"
       #
       # On Ubuntu use update-rc.d to manage services
       # On CentOS/RedHat use chkconfig to manage services
       #
       if os.path.exists("/usr/sbin/update-rc.d"):
           cmdList=[ "/usr/sbin/update-rc.d", "-f", initdName, "remove"]
       else:
           cmdList=[ "/sbin/chkconfig", "--del", initdName]
       cmdList.extend([sep, "/bin/rm", initdBinPath])
       if force:
          cmdList.extend(["||", "true"])
       scidb.printDebug("cmd = %s"%(str(cmdList)))
       return cmdList

    def getServiceRegisterCmd(self, srv):
       configCopyPath = self.getConfigDBFilename(srv)
       cmdList = ["/bin/chmod", "a-rwx,u+r", configCopyPath+".tmp"]
       cmdList.extend(["&&", "/bin/mv", configCopyPath+".tmp", configCopyPath])
       cmdList.extend(["&&", "/bin/chmod", "a-rwx,u+r", configCopyPath])
       cmd = " ".join(cmdList)
       scidb.printDebug("cmd = %s"%(cmd))
       return cmd

    def getServiceUnregisterCmd(self, srv, force=False):
       version = self.getScidbVersion()
       configCopyPath = self.getConfigDBFilename(srv)

       if force:
          sep=";"
       else:
          sep="&&"

       cmdList=["/bin/rm", "-f", configCopyPath+".tmp"]
       cmdList.extend([sep, "/bin/rm", configCopyPath])
       if force:
          cmdList.extend(["||", "true"])
       cmd = " ".join(cmdList)
       scidb.printDebug("cmd = %s"%(cmd))
       return cmd

    def getDBConfig(self):
       config = SafeConfigParser()
       # from python doc:
       # When adding sections or items, add them in the reverse order of
       # how you want them to be displayed in the actual file.
       # In addition, please note that using RawConfigParser's and the raw
       # mode of ConfigParser's respective set functions, you can assign
       # non-string values to keys internally, but will receive an error
       # when attempting to write to a file or when you get it in non-raw
       # mode. SafeConfigParser does not allow such assignments to take place.
       config.add_section(self._ctx._scidb_name)
       for key,value in self._ctx._configOpts.iteritems():
           if key != "db_passwd" :
               config.set(self._ctx._scidb_name, key, str(value))
       return config

def handle(superParser, superArgs, cmdArgs=[], argv=None):

   scidb._DBG = superArgs.verbose
   cmdExec = P4CmdExecutor(scidb.gCtx)

   modName="p4_system"
   parser = argparse.ArgumentParser(prog=superParser.prog+" -m "+modName)

   subparsers = parser.add_subparsers(dest='subparser_name',
                                      title="Module \'%s\'"%(modName),
                                      description="Paradigm4 extensions for SciDB administration and configuration. "+
                                      "Use -h/--help with a particular subcommand from the list below to learn its usage")

   subParser = subparsers.add_parser('start_server', description="Start SciDB instances assigned to a given server")
   group = subParser.add_mutually_exclusive_group(required=True)
   group.add_argument('--all', action='store_true', help="start instance processes on all servers. Unlike start_all, does not confirm that SciDB is on-line. ")
   group.add_argument('-si', '--server_id', help="server ID as specified in config.ini (server-ID=...)")
   subParser.add_argument('-if', '--instance_filter', default=None, help="Server instance IDs as specified in config.ini (server-id=host,SERVER_INSTANCE_IDS) using the same \'n,m-p,q-s,...\' format. Only the specified instances on the specified server are started.")
   subParser.add_argument('scidb_name', help="SciDB name as specified in config.ini")
   subParser.add_argument('config_file', default=None, nargs='?', help="config.ini file to use, default is /opt/scidb/<version>/etc/config.ini")
   subParser.set_defaults(func=cmdExec.start_server)

   subParser = subparsers.add_parser('stop_server', description="Stop SciDB instances assigned to a given server")
   group = subParser.add_mutually_exclusive_group(required=True)
   group.add_argument('--all', action='store_true', help="stop instance processes on all servers")
   group.add_argument('-si', '--server_id', help="server ID as specified in config.ini (server-ID=...)")
   subParser.add_argument('-if', '--instance_filter', default=None, help="Server instance IDs as specified in config.ini (server-id=host,SERVER_INSTANCE_IDS) using the same \'n,m-p,q-s,...\' format. Only the specified instances on the specified server are stopped.")
   subParser.add_argument('scidb_name', help="SciDB name as specified in config.ini")
   subParser.add_argument('config_file', default=None, nargs='?', help="config.ini file to use, default is /opt/scidb/<version>/etc/config.ini")
   subParser.set_defaults(func=cmdExec.stop_server)

   subParser = subparsers.add_parser('status_server', description="Check SciDB instance processes assigned to a given server")
   group = subParser.add_mutually_exclusive_group(required=True)
   group.add_argument('--all', action='store_true', help="check instance processes on all servers")
   group.add_argument('-si', '--server_id', help="server ID as specified in config.ini (server-ID=...)")
   subParser.add_argument('scidb_name',   help="SciDB name as specified in config.ini")
   subParser.add_argument('config_file', default=None, nargs='?', help="config.ini file to use, default is /opt/scidb/<version>/etc/config.ini")
   subParser.set_defaults(func=cmdExec.status_server)

   subParser = subparsers.add_parser('service_register', description=
                                     "Register scidb_name with the SciDB Linux SysV service on a given server.\n"+
                                     "Zero or more SciDB DB names can be registered with SciDB Linux service, "+
                                     "the service manages them together as one unit.\n"+
                                     "The SciDB service must be 'service_add()'ed on the server for this command to have effect.")
   group = subParser.add_mutually_exclusive_group(required=True)
   group.add_argument('--all', action='store_true', help="register on all servers")
   group.add_argument('-si', '--server_id', help="server ID as specified in config.ini (server-ID=...)")
   subParser.add_argument('scidb_name',   help="SciDB name as specified in config.ini")
   subParser.add_argument('config_file', default=None, nargs='?', help="config.ini file to use, default is /opt/scidb/<version>/etc/config.ini")
   subParser.set_defaults(func=cmdExec.service_register)

   subParser = subparsers.add_parser('service_unregister', description=
                                     "Unregister scidb_name from the SciDB Linux SysV service on a given server.\n"+
                                     "Any other registered DB names are unaffected.")
   group = subParser.add_mutually_exclusive_group(required=True)
   group.add_argument('--all', action='store_true', help="unregister on all servers")
   group.add_argument('-si', '--server_id', help="server ID as specified in config.ini (server-ID=...)")
   subParser.add_argument('scidb_name',   help="SciDB name as specified in config.ini")
   subParser.add_argument('config_file', default=None, nargs='?', help="config.ini file to use, default is /opt/scidb/<version>/etc/config.ini")
   subParser.add_argument('-f','--force', action='store_true', help="perform all steps even if some fail")
   subParser.set_defaults(func=cmdExec.service_unregister)

   subParser = subparsers.add_parser('service_add', description=
                                     "Add a SciDB Linux SysV service on the local host.\n"+
                                     "Must be executed with root priviliges.\n"+
                                     "It requires the sshd service to be present on the host.\n"+
                                     "It performs the following steps:\n"+
                                     "-- copy /opt/scidb/<version>/bin/scidb.initdb to /etc/init.d/SciDB-<version> "+
                                     "after making relevant updates to the original file\n"+
                                     "-- invoke chown user /opt/scidb/<version>/service\n"+
                                     "-- add service SciDB-<version>\n")
   subParser.add_argument('-u','--user', required=True, help="OS user name under which the SciDB service will run SciDB instances, "+
                          "default is this process' effective user id name")
   subParser.set_defaults(func=cmdExec.service_add)

   subParser = subparsers.add_parser('service_remove', description=
                                     "Remove a SciDB Linux SysV service from the local host.\n"+
                                     "Must be executed with root priviliges.\n"+
                                     "It performs the following steps:\n"+
                                     "-- remove service SciDB-<version>\n"+
                                     "-- remove /etc/init.d/SciDB-<version>\n")
   subParser.add_argument('-f','--force', action='store_true', help="perform all steps even if some fail")
   subParser.set_defaults(func=cmdExec.service_remove)

   subParser = subparsers.add_parser('config_server', description="Configure SciDB instances assigned to a given server")
   group = subParser.add_mutually_exclusive_group(required=True)
   group.add_argument('-rm', '--remove_delta', help="""file containing descriptions for the instances to be unregistered from SciDB.
config_remove_delta.ini format:
[ server-X=IP|Host,n,m-p,q-s, ... ]+
NOTE: If --force is specified, existing instance data directories and unknown instances are ignored.
""")
   group.add_argument('-add', '--add_delta', help="""file containing descriptions for the new instances to be registered with SciDB.
                      "config_add_delta.ini format:
                      "[ server-X=IP|Host,n,m-p,q-s, ... ]+
                      "[ data-dir-prefix-X-y=<per_instance_dir>, where y is one of {0-n m-p q-s} ]*
                      "NOTE: If --force is specified, existing instance data directories are removed before initialization.
""")
   subParser.add_argument('-f','--force', action='store_true', help="Action specific flag see --remove_delta,--add_delta")
   subParser.add_argument('-out','--output', required=True, help="New config.ini file. '-' means stdout")
   subParser.add_argument('-A', '--auth-file', default=None, nargs='?', help="name of file containing authentication info")
   subParser.add_argument('scidb_name', help="SciDB name as specified in config.ini")
   subParser.add_argument('config_file', default=None, nargs='?', help="config.ini file to use, default is /opt/scidb/<version>/etc/config.ini")
   subParser.set_defaults(func=cmdExec.config_server)

   args = parser.parse_args(cmdArgs)

   scidb.gCtx = scidb.getContext(args, argv)
   cmdExec._ctx = scidb.gCtx

   try:
      args.func()
   except Exception, e:
      scidb.printError("Command %s failed: %s\n"% (args.subparser_name,str(e)))
      if scidb._DBG:
         traceback.print_exc()
         sys.stderr.flush()
      raise
