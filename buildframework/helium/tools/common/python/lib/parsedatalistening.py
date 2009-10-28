#============================================================================ 
#Name        : parsedatalistening.py 
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

import urllib
import gzip
import tempfile
import os
import sys
import xml.etree.ElementTree as ElementTree
from processing import Pool, freezeSupport

class Target:
    def __init__(self, name, start, end):
        self.name = name
        self.start = start
        self.end = end
      
class Build:
    def __init__(self, id, user, success, targets):
        self.id = id
        self.user = user
        self.success = success
        self.targets = targets

def parseXml(infile):
    f = gzip.open(infile, 'r')
    success = True
    username = ''
    targets = []
    for event, elem in ElementTree.iterparse(f):
        if elem.tag == 'build':
            name = elem.get('status')
            if name != 'successful':
                success = False
        if elem.tag == 'target':
            name = elem.get('name')
            id = elem.get('id')
            if name != None:
                targets.append(Target(name, id, 0))
        if elem.tag == 'targetRef':
            ref = elem.get('reference')
            if ref != None:
                for t in targets:
                    if t.start == ref:
                        t.start = int(elem.get('startTime'))
                        t.end = int(elem.get('endTime'))
        if elem.tag == 'property':
            if elem.get('name') == 'user.name':
                username = elem.get('value')
            
        elem.clear()
    
    f.close()

    return Build(infile, username, success, targets)

if __name__ == '__main__':
    freezeSupport()
        
    outdir = os.path.join(tempfile.gettempdir(), 'helium_data')
    if not os.path.exists(outdir):
        os.mkdir(outdir)
    
    files = []
    pool = Pool()
    
    for n in range(1, 100):
    
        try:
            #r'C:\USERS\helium\helium_data'
            infile = os.path.join(outdir, '%(#)08d_data.xml.gz' % {"#": n})
            #print infile
            if not os.path.exists(infile):
                urllib.urlretrieve("http://helium.nmp.nokia.com/data/internaldata/%(#)08d_data.xml.gz" % {"#": n}, infile)
            
            files.append(infile)
    
        except Exception, e:
            print e
    
    builds = pool.map(parseXml, files)
    
    targets = {}
    targetsfailing = {}
    users = {}
    
    for build in builds:

        if users.has_key(build.user):
            users[build.user] = users[build.user] + 1
        else:
            users[build.user] = 1
        
        for value in build.targets:
            #print build.targets
            #value = build.targets.pop()
            #print value.name
            #print (value.end - value.start)/1000
                
            if targets.has_key(value.name):
                #targets[value.name] = targets[value.name] + 1
                (no, time) = targets[value.name]
                targets[value.name] = (no + 1, time + (value.end - value.start))
            else:
                targets[value.name] = (1, (value.end - value.start))
            
            if not build.success:
                if targetsfailing.has_key(value.name):
                    targetsfailing[value.name] = targetsfailing[value.name] + 1
                else:
                    targetsfailing[value.name] = 1
    
    print 'Users:'
        
    for key in users.keys():
        print '%05d' % users[key] + ' ' + key
    
    print 'Calls,Targets,TimeSeconds'
    
    for key in targets.keys():
        (no, time) = targets[key]
        print '%05d' % no + ',' + key + ',%07d' % int(time/1000)
    
    print 'Targets failing:'
    
    for key in targetsfailing.keys():
        print '%05d' % targetsfailing[key] + ' ' + key