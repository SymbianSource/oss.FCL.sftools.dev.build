#============================================================================ 
#Name        : extra.py 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description:
#===============================================================================

""" Library that contains custom Synergy functionnlities: e.g
        * Snapshotter that can snapshot unfrozen baselines
        * Threaded snapshotter.
"""
import ccm
import os
import shutil
import threading
import threadpool
import traceback
import sys
import logging
import xml.dom.minidom
from xml.dom.minidom import getDOMImplementation, parse

# Uncomment this line to enable logging in this module, or configure logging elsewhere
#logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger('ccm.extra')

class CCMExtraException(ccm.CCMException):
    """ Exception raised by the methods of this module. """
    def __init__(self, description, subexceptions):
        ccm.CCMException.__init__(self, description)
        self.subexceptions = subexceptions
    
    

def Snapshot(project, targetdir, dir=None):
    """ This function can snapshot anything from Synergy, even prep/working projects """
    assert project != None, "a project object must be supplied"
    assert project.type == "project", "project must be of project type"
    if not dir:
        dir = project.root_dir()
    targetdir = os.path.join(targetdir, dir.name)
    os.makedirs(targetdir)
    for object in dir.children(project):
        if object.type == 'dir':
            Snapshot(project, targetdir, object)
        elif object.type == 'project':
            Snapshot(object, targetdir)
        else:
            object.to_file(os.path.join(targetdir, object.name))


class _FastSnapshot:
    """ Snapshot Job executed by the thread pool. """
    def __init__(self, pool, project, targetdir, callback, exc_hld):
        """ Construtor, will store the parameter for the checkout. """
        self.pool = pool
        self.project = project
        self.targetdir = targetdir
        self.callback = callback
        self.exc_hld = exc_hld

    def __call__(self):
        """ Do the checkout, and then walkthrough the project hierarchy to find subproject to snapshot. """
        _logger.info("Snapshotting %s under %s" % (self.project, self.targetdir))
        self.project.snapshot(self.targetdir, False)
        def walk(dir, targetdir):
            for object in dir.children(self.project):
                if isinstance(object, ccm.Dir):
                    walk(object, os.path.join(targetdir, object.name))
                elif isinstance(object, ccm.Project):
                    _logger.info("Adding project %s" % object.objectname)
                    self.pool.addWork(_FastSnapshot(self.pool, object, targetdir, self.callback, self.exc_hld))
                    
        if len(self.project.subprojects) > 0:
            rootdir = self.project.root_dir()
            walk(rootdir, os.path.join(self.targetdir, rootdir.name))
        return ""

def FastSnapshot(project, targetdir, threads=4):
    """ Create snapshot running by running snapshots concurrently.
        Snapshot will be made recursively top-down, and each sub project will
        be snapshotted in parallel. 
    """
    assert threads > 0, "Number of threads must be > 0."
    assert project != None, "a project object must be supplied."
    assert project.type == "project", "project must be of project type."
    
    # error handling
    exceptions = []
    results = []
    def handle_exception(request, exc_info):
        _logger.error( "Exception occurred in request #%s: %s" % (request.requestID, exc_info[1]))
        exceptions.append(exc_info[1])                        

    def handle_result(request, result):        
        results.append(result)
   
    pool = threadpool.ThreadPool(threads)
    pool.addWork(_FastSnapshot(pool, project, targetdir, handle_result, handle_exception))
    pool.wait()
    
    if len(exceptions):
        raise CCMExtraException("Errors occurred during snapshot.", exceptions)

    return "\n".join(results)



def FastMaintainWorkArea(project, path, pst=None, threads=4, wat=False):
    """ Maintain the workarea of a project in parallel. """
    assert threads > 0, "Number of threads must be > 0."
    assert isinstance(project, ccm.Project), "a valid project object must be supplied."
            
    # error handling
    exceptions = []
    results = []
    def handle_exception(request, exc_info):
        _logger.error( "Exception occured in request #%s: %s\n%s" % (request.requestID, exc_info[1], traceback.format_exception(exc_info[0], exc_info[1], exc_info[2])))
        exceptions.append(exc_info[1])
    
    def handle_result(request, result):        
        results.append(result)

    class __MaintainProject:
        def __init__(self, subproject, toplevel, wat=False):
            self.subproject = subproject
            self.toplevel = toplevel
            self.wat = wat
        
        def __call__(self):
            output = ""
            _logger.info("Maintaining project %s" % self.subproject)
            for tuple in self.subproject.finduse():
                if tuple['project'] == self.toplevel:
                    self.subproject['wa_path'] = os.path.join(self.toplevel['wa_path'], tuple['path'])
                    self.subproject["project_subdir_template"] = ""
                    _logger.info("Maintaining project %s under %s" % (self.subproject, self.subproject['wa_path']))
                    output = self.subproject.work_area(True, True, True, wat=self.wat)
            _logger.info("Project %s maintained" % self.subproject)
            return output
            
    pool = threadpool.ThreadPool(threads)
    project.work_area(True, False, True, path, pst, wat=wat)
    for subproject in project.get_members(type="project"):
        _logger.info("Adding project %s" % subproject)
        pool.addWork(__MaintainProject(subproject, project, wat), callback=handle_result, exc_callback=handle_exception)
    pool.wait()
    
    if len(exceptions) > 0:
        raise CCMExtraException("Errors occured during work area maintenance.", exceptions)
    
    return "\n".join(results)



def get_toplevel_project(session, path):
    try:
        wainfo = session.get_workarea_info(path)
        project = get_toplevel_project(session, os.path.dirname(wainfo['path']))
        if project == None:
            project = wainfo['project']
        return project
    except ccm.CCMException, e:
        return None


class SessionProvider:
    def __init__(self, opener=None):
        self._opener = opener
        if self._opener is None:
            self._opener = ccm.open_session
        
    def get(self, username=None, password=None, engine=None, dbpath=None, database=None, reuse=True):
        _logger.debug("SessionProvider: Creating a new session.")
        return self._opener(username, password, engine, dbpath, database, reuse)

    def __del__(self):
        _logger.info("Deleting the session provider.")
        self.close()

    def close(self):
        pass
        
        
class CachedSessionProvider(SessionProvider):
    """
<sessions>
    <session database="foobar" ccmaddr="xxxx"/>
    <session database="foobarx" ccmaddr="xxxx"/>
</sessions>
    """

    def __init__(self, opener=None, cache=None):
        """ Creates CachedSessionProvider, with a specific 
            opener and cache file.
        """
        SessionProvider.__init__(self, opener=opener)
        _logger.info("Using CachedSessionProvider.")
        self.__closed = False
        self._lock = threading.Lock()
        self.cacheXml = cache
        self.cacheFree = {}
        self.cacheUsed = []
        self.load()

    
    def close(self):
        """ Closing the SessionProvider. """
        _logger.info("Closing the CachedSessionProvider.")
        self.save()
        if self.cacheXml == None:
            _logger.info("Cleaning up opened sessions.")
            self._lock.acquire()
            for dbname in self.cacheFree.keys():
                while len(self.cacheFree[dbname]) > 0:
                    session = self.cacheFree[dbname].pop()
                    session.close_on_exit = True
                    session.close()
            while len(self.cacheUsed) > 0:
                session = self.cacheUsed.pop()
                session.close_on_exit = True
            self._lock.release()
        self.__closed = True   
    
    def save(self):
        if self.cacheXml is not None and not self.__closed:
            _logger.info("Writing %s" % self.cacheXml)
            impl = getDOMImplementation()
            sessions = impl.createDocument(None, "sessions", None)
            top_element = sessions.documentElement
            self._lock.acquire()
            def add_session(dbname, session):
                sessionNode = sessions.createElement("session")
                sessionNode.setAttribute("database", dbname)
                sessionNode.setAttribute("ccmaddr", session.addr())
                top_element.appendChild(sessionNode)
            for dbname in self.cacheFree.keys():
                for session in self.cacheFree[dbname]:
                    add_session(dbname, session)
            for session in self.cacheUsed:
                add_session(session.database(), session)
            self._lock.release()
            o = open(self.cacheXml, "w+")
            o.write(sessions.toprettyxml())
            o.close()
            _logger.debug(sessions.toprettyxml())
            
    
    def load(self):
        if self.cacheXml is not None and os.path.exists(self.cacheXml):
            _logger.info("Loading %s" % self.cacheXml)
            doc = parse(open(self.cacheXml, 'r')) 
            sessions = doc.documentElement
            self._lock.acquire()
            try:
                for child in sessions.childNodes:
                    if child.nodeType == child.ELEMENT_NODE and child.tagName == "session" and child.hasAttribute('database') and child.hasAttribute('ccmaddr'):
                        if child.getAttribute('database') not in self.cacheFree:
                            self.cacheFree[child.getAttribute('database')] = []
                        if ccm.session_exists(child.getAttribute('ccmaddr'), child.getAttribute('database')):
                            _logger.info(" + Session: database=%s, ccmaddr=%s" % (child.getAttribute('database'), child.getAttribute('ccmaddr')))
                            self.cacheFree[child.getAttribute('database')].append(ccm.Session(None, None, None, ccm_addr=child.getAttribute('ccmaddr'), close_on_exit=False))
                        else:
                            _logger.info(" - Session database=%s, ccmaddr=%s doesn't seem to be valid anymore." % (child.getAttribute('database'), child.getAttribute('ccmaddr')))
            finally:
                self._lock.release()

    
    def get(self, username=None, password=None, engine=None, dbpath=None, database=None, reuse=True):
        if self.__closed:
            raise Exception("Could not create further session the provider is closed.")
        _logger.debug("CachedSessionProvider: Getting a session.")
        if database is not None and database in self.cacheFree and len(self.cacheFree[database]) > 0:
            _logger.info("CachedSessionProvider: Reusing session.")
            self._lock.acquire()
            s = self.cacheFree[database].pop()
            self.cacheUsed.append(s)
            self._lock.release()
            return CachedProxySession(self, s) 
        else:
            _logger.debug("CachedSessionProvider: Creating new session.")
            session = SessionProvider.get(self, username, password, engine, dbpath, database, False)
            session.close_on_exit = False
            s = CachedProxySession(self, session)
            db = s.database()
            self._lock.acquire()
            if db not in self.cacheFree:
                self.cacheFree[db] = []
            self.cacheUsed.append(session)
            self._lock.release()
            return s

    def free(self, session):
        _logger.debug("CachedSessionProvider: Freeing session: %s" % session)
        db = session.database()
        if session in self.cacheUsed:
            _logger.debug("CachedSessionProvider: Removing session from used list.")
            self._lock.acquire()
            self.cacheUsed.remove(session)
            self.cacheFree[db].append(session)
            self._lock.release()

class CachedProxySession:
    """ Proxy session which will cleanup the session and free it from the provider """
    
    def __init__(self, provider, session):
        """ Constructor. """
        self.__session = session 
        self.__provider = provider
    
    def __getattr__(self, attrib):
        """ Delegate attributes to the session object. """
        _logger.debug("CachedProxySession.__getattr__(%s)" % attrib)
        if attrib == "close":
            return self.__close
        return getattr(self.__session, attrib)

    def __close(self):
        """ Overriding the session closing. """
        _logger.debug("CachedProxySession.__close")
        self.__provider.free(self.__session)
        self.__session.close()
        
    def __del__(self):
        """ Free the session on destruction. """
        _logger.debug("CachedProxySession.__del__")
        self.__close()

