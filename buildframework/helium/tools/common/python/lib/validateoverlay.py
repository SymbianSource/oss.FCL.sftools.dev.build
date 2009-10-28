#============================================================================ 
#Name        : validateoverlay.py 
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



import StringIO
import sys
import os
import optparse
import traceback

import amara

import ccm
import comments
import helium.logger
from helium.outputer import XML2XHTML
import nokia.nokiaccm
import virtualbuildarea


def __findChild(p, d, name):
    if (p is None or d is None):
        return None
    for child in d.children(p):
        if name.lower() == child.name.lower():
            return child
    return None

def __getDir(p, o):
    if (o.type == 'project'):
        return o, o.root_dir()
    return p, o

class ValidateOverlayInfo:
    UNKNOW = 0
    STILL_VALID = 1
    MERGE = 2
    def __init__(self, name):
        self.name = name
        #self.status = status
        self.overlayObject = None
        self.deliveryObjects = []

def ValidateOverlay(vproject, vdir, oproject, odir, extraobject = None):
    """ This function scan an the virtual build area and the overlay to validate
        if the overlay content is still up to date compare to the delivery.
    """
    if extraobject is None:
        extraobject = []
    print "ValidateOverlay(%s,%s,%s,%s)" % (vproject, vdir, oproject, odir)
    result = {'name': odir.name, 'content': []}
    for child in odir.children(oproject):
        o = __findChild(vproject, vdir, child.name)
        if o is None:
            if (child.type == 'dir' or child.type == 'project'):
                op, oo = __getDir(oproject, child)
                result['content'].append(ValidateOverlay(None, None, op, oo, extraobject))
            else:
                info = ValidateOverlayInfo(child.name)
                info.overlayObject = child
                result['content'].append(info)
        else:
            if (child.type == 'dir' or child.type == 'project'):
                vp, vo = __getDir(vproject, o)
                op, oo = __getDir(oproject, child)
                result['content'].append(ValidateOverlay(vp, vo, op, oo, extraobject))
            else:
                info = ValidateOverlayInfo(child.name)
                info.overlayObject = child
                info.deliveryObjects.append({'status': ValidateOverlayInfo.UNKNOW, 'object': o})
                
                for eo in extraobject:
                    if eo.is_same_family(o):
                        info.deliveryObjects.append({'status': ValidateOverlayInfo.UNKNOW, 'object': eo})
                
                for delivery in info.deliveryObjects:
                    if child.is_recursive_sucessor_of(delivery['object']):
                        delivery['status'] = ValidateOverlayInfo.STILL_VALID
                    else:
                        delivery['status'] = ValidateOverlayInfo.MERGE

                result['content'].append(info)
    return result

def getObjectPath(project, spath, dir=None):
    name = spath.pop(0)
    if (dir == None):        
        if project.root_dir().name.lower() == name.lower():
            return getObjectPath(project, spath, project.root_dir())
        raise Exception("project.root_dir().name.lower()!=name.lower():")
    else:
        for o in dir.children(project):
            if o.name.lower() == name.lower():
                if len(spath) == 0:
                    return o
                elif o.type == 'dir':
                    return getObjectPath(project, spath, o)
                else:
                    raise Exception("Object could not be accessed")
        raise Exception("Object not found")
 
def showBranchInfo(logger, object):    
    doc = comments.CommentParser.scan_content(str(object.overlayObject), object.overlayObject.content(), "branchInfo")
    if len(doc.commentLog.xml_xpath('branchInfo'))>0:
        for child in doc.commentLog.xml_xpath('branchInfo'):
            logger.PrintRaw("<b>Branch Information:</b>\n")
            if hasattr(child, 'xml_attributes'):
                for attr in child.xml_attributes:
                    logger.PrintRaw("<b>%s:</b> %s\n" % (attr, getattr(child, attr)))
                    if hasattr(child, 'branch'):
                        logger.PrintRaw("<b>Should validate compare to file:</b> %s\n" % child.branch)
    else:
        logger.Print("No branch info...\n")

def showValidity(logger, obj):
    if len(obj.deliveryObjects)==0:
        logger.NotFound("Could not find %s relative objects." % (obj.overlayObject))                
    else:
        for delivery in obj.deliveryObjects:
            if (delivery['status'] == ValidateOverlayInfo.MERGE):
                logger.Merge("Overlay object %s requires a merge with %s." % (obj.overlayObject, delivery['object']))
            elif (delivery['status'] == ValidateOverlayInfo.STILL_VALID):
                logger.Valid("%s is still a successor of %s." % (obj.overlayObject, delivery['object']))
    

def showValidateOverlayInfo(logger, data, comments=False):
    logger.OpenEvent(data['name'])
    for o in data['content']:
        if isinstance(o, ValidateOverlayInfo):            
            logger.OpenEvent(o.name)
            showValidity(logger, o)                    
            # Showing branch information.
            if comments:
                showBranchInfo(logger, o)
            logger.CloseEvent()
        else:
            showValidateOverlayInfo(logger, o, comments)
    logger.CloseEvent()

def mergeObjects(logger, data, task):
    for obj in data['content']:
        if isinstance(obj, ValidateOverlayInfo):
            mergedobject = None
            for delivery in obj.deliveryObjects:
                if (delivery['status'] == ValidateOverlayInfo.MERGE):
                    try:
                        if not mergedobject:
                            (mergedobject, validity) = obj.overlayObject.merge(delivery['object'], task)
                            mergedobject.checkin('public', 'Makes object public.')
                            logger.Print("%s (%s, %s)" % (mergedobject, obj.overlayObject, delivery['object']))
                        else:
                            delivery['object'].relate(mergedobject)
                            logger.Print("%s (%s, %s)" % (mergedobject, obj.overlayObject, delivery['object']))
                            #mergedobject
                    except Exception, e:
                        logger.Error("%s" % e)
#            if o.status == ValidateOverlayInfo.MERGE:            
#                try:
#                    (object, validity) = o.overlayObject.merge(o.deliveryObject, task)
#                    object.checkin('public', 'Makes object public.')
##                   logger.Print("%s (%s, %s)" % (object, o.overlayObject, o.deliveryObject))
#                except Exception, e:
#                    logger.Error("%s" % e)
        else:
            mergeObjects(logger, obj, task)


def validate(session, inputfile, overlaydir, showBranchInfo, createtask=False, releasetag = None, extra_objects = None, logname = "validate_overlay"):
    """ Validate an overlay uisng data from the inputfile to generate the virtual build area. """
    vba = virtualbuildarea.create(session, open(inputfile, 'r'))
    print overlaydir
    if extra_objects is None:
        extra_objects = []
    overlay = session.get_workarea_info(overlaydir)['project']
    voresult = ValidateOverlay(vba, vba.root_dir(), overlay, getObjectPath(overlay, [overlay.name, 'common', 'files']), extra_objects)

    mclogger = helium.logger.Logger()
    mclogger.SetInterface("http://fawww.europe.nokia.com/isis/isis_interface/")
    mclogger.SetTitle("Validate Overlay")
    mclogger.SetSubTitle("Validating: %s" % overlay)
    mclogger.OpenMainContent("Analysing %s" % overlay)
    showValidateOverlayInfo(mclogger, voresult, showBranchInfo)
    mclogger.CloseMainContent()
    if createtask and releasetag != None:
        mclogger.OpenMainContent("Creating merge task")
        team = 'TEAM_NAME'
        if os.environ.has_key('TEAM'):
            team = os.environ['TEAM']            
        try:
            task = ccm.Task.create(session, session.create(releasetag), "%s: %s: %s: Merge task" % (team, overlay.name, os.environ['USERNAME']))
            #task = session.create("Task fa1f5132#17458")
            task.assign(os.environ['USERNAME'])
            mclogger.Print("Created task %s.\n" % task['displayname'])
            mergeObjects(mclogger, voresult, task)
        except Exception, e:
            traceback.print_exc(file=sys.stdout)
            mclogger.Error(e)
        mclogger.CloseMainContent()
    
    mclogger.WriteToFile(logname + ".xml")
    g = XML2XHTML(logname+".xml")    
    g.addCSSLink("http://fawww.europe.nokia.com/isis/isis_interface/css/overlaycheck.css")
    g.generate()
    g.WriteToFile(logname + ".html")


def main():

    usage = "usage: %prog [options] arg1 arg2"
    parser = optparse.OptionParser(usage=usage)
    parser.add_option("--host", dest="ccm_host", action="store",
                                help="Synergy Host")
    parser.add_option("-d", "--db", dest="ccm_db", action="store",
                                help="Synergy database")
    parser.add_option("-u", "--username", dest="ccm_login",  action="store",                    
                                help="Synergy username")
    parser.add_option("-p", "--password", dest="ccm_password",  action="store",                    
                                help="Synergy user password")    
    parser.add_option("-c",  "--config", dest="inputfile", action="store",
                                help="Configuration file", metavar="PATH")
    parser.add_option("-o", "--overlay", dest="overlaydir", action="store",
                                help="Overlay work area directory", metavar="PATH")
    parser.add_option("--showBranchInfo", dest="showBranchInfo", action="store_true",
                                help="Show up branch information", default=False)
    parser.add_option("--ct", dest="createtask", action="store_true",
                                help="Create merge task", default=False)
    parser.add_option("--rt", dest="releasetag", action="store",
                                help="Release tag", default=None)

    (options, args) = parser.parse_args()
    session = nokia.nokiaccm.open_session(options.ccm_login, options.ccm_password, options.ccm_host, options.ccm_db)
    validate(session, options.inputfile, options.overlaydir, options.showBranchInfo, options.createtask, options.releasetag)
    session.close()

if __name__ == "__main__":
    main()

#vba = virtualbuildarea.VirtualProject(session,'vba')

#try:
#    #dom = xml.dom.minidom.parse(input)
#    dom = xml.dom.minidom.parseString(input)
#except Exception, e:
#    raise Exception("XML cannot be parsed properly %s" % e)
#
#virtualBA = dom.documentElement
#for child in virtualBA.childNodes:
#    if (child.nodeType == xml.dom.Node.ELEMENT_NODE) and (child.nodeName=='add'):
#        print "add node :%s (%d)" % (child.getAttribute('project'),len(child.childNodes))
#        pathobject = createVirtualPath(child.getAttribute('to').split('/'),vba)
#        if len(child.childNodes)==0:
#            p = session.create(child.getAttribute('project'))
#            pathobject.addChild(p,p)
#        else:
#            project = session.create(child.getAttribute('project'))
#            for subChild in child.childNodes:
#                if (subChild.nodeType == xml.dom.Node.ELEMENT_NODE) and (subChild.nodeName=='objects'):
#                    spath = removeEmptyStrings(subChild.getAttribute('from').split('/'))
#                    for t in getObjects(project,spath):
#                        pathobject.addChild(t['object'],t['project'])
#                    


#print "******************************************"
def showVirtualContent(project, path, indent=''):
    if not isinstance(path, virtualbuildarea.VirtualDir):
        return
    print "%s+ %s" % (indent, path)
    indent += "   "
    for obj in path.children(project):        
        if (obj.type == 'dir'):
            showVirtualContent(project, obj, indent)
        else:
            print "%s- %s" % (indent, obj)
    
#showVirtualContent(vba, vba.root_dir())

def get_additional_delivery_objects(session, deliveryinput):
    objects = []
    delivery = amara.parse(open(deliveryinput, 'r'))
    for t in delivery.xml_xpath('/deliveryConfiguration//task[@id]'):
        for task in map(lambda x: x.strip(), t.id.split(',')):
            objects.extend(session.create("Task %s" % task).objects)
    for f in delivery.xml_xpath('/deliveryConfiguration//folder[@id]'):
        for folder in map(lambda x: x.strip(), f.id.split(',')):
            objects.extend(session.create("Folder %s" % folder).objects)
    return objects

