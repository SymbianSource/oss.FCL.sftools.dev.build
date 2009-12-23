#============================================================================ 
#Name        : sbsscanlog.py 
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

import os
import sys
import re
import xml.sax
import datetime
import time
from xml.sax.handler import ContentHandler
from xml.dom.minidom import parse, parseString
from xml.sax.saxutils import XMLGenerator
from xml.sax.xmlreader import AttributesNSImpl
import codecs
from optparse import OptionParser

START_TAG_REG_EX = "<recipe|<error|<warning"

IGNORE_TEXT_REG_EX = "warning: no newline at end of file"

DEFAULT_STRING = "general"

END_TAG_REG_EX = "</recipe>|</error>|</warning>"

DEFAULT_CONFIGURATION = {    "FATAL":     [r"mingw_make.exe"],
                            "ERROR": [ r'\): Missing file:', r'^(?:(?:\s*\d+\)\s*)|(?:\s*\*\*\*\s*))ERROR:',
                                        r"^MISSING:",
                                        r"Error:\s+", r"'.+' is not recognized as an internal or external command",
                                        r"FLEXlm error:",
                                        r"(ABLD|BLDMAKE) ERROR:",
                                        r"FATAL ERROR\(S\):",
                                        r"fatal error U1077",
                                        r"warning U4010",
                                        r"^make(?:\[\d+\])?\: \*\*\*",
                                        r"^make(?:\[\d+\])?:\s+.*\s+not\s+remade",
                                        r"\"(.*)\", line (\d+): (Error: +(.\d+.*?):.*)$",
                                        r"error: ((Internal fault):.*)$",
                                        r"Exception: [A-Z0-9_]+",
                                        r"target .* given more than once in the same rule",
                                        r"^ERROR:",
                                        r"^ERROR EC\d+:",
                                        r"Errors caused tool to abort.",
                                        r"^ERROR\t",],
                         "CRITICAL": [r"[Ww]arning:?\s+(#111-D|#1166-D|#117-D|#128-D|#1293-D|#1441-D|#170-D|#174-D|#175-D|#185-D|#186-D|#223-D|#231-D|#257-D|#284-D|#368-D|#414-D|#430-D|#47-D|#514-D|#546-D|#68-D|#69-D|#830-D|#940-D|#836-D|A1495E|L6318W|C2874W|C4127|C4355|C4530|C4702|C4786|LNK4049)"],
                         "WARNING": [r'^(\d+\))?\s*WARNING:', r'^MAKEDEF WARNING:',
                                        r'line \d+: Warning:', r':\s+warning\s+\w+:',
                                        r"\\\\(.*?)\(\d+\)\s:\sWarning:\s\(\d+\)",
                                        r"^(BLDMAKE |MAKEDEF )?WARNING:",
                                        r"WARNING\(S\)",
                                        r"\(\d+\) : warning C",
                                        r"LINK : warning",
                                        r":\d+: warning:",
                                        r"\"(.*)\", line (\d+): (Warning: +(?!A1495E)(.\d+.*?):.*)$",
                                        r"Usage Warning:",
                                        r"mwld.exe:",
                                        r"^Command line warning",
                                        r"ERROR: bad relocation:",
                                        r"^(\d+) warning",
                                        r"EventType:\s+Error\s+Source:\s+SweepNT",
                                        r"^WARN\t",
                                      ],
                        "REMARK": [r"Command line warning D4025 : ",
                                        r"^REMARK: ",
                                        r"^EventType:\s+Error\s+Source:\s+GNU\s+Make",
                                        r":\d+: warning: cannot find matching deallocation function",
                                        r"((:\d+)*: note: )",
                                   ],
                        "INFO": [r"^INFO:"]
                        }

def find_priority(line, config):
    """ finds the error prioroty of the given line of text"""
    keys = config.keys()
    keys.reverse()    
    for category in keys:
        for rule in config[category]:
            if rule.search(line) != None:
                return category.lower()
    return "stdout"

def getText(nodelist):
    rc = ""
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            rc = rc + node.data
    return rc

class SBSScanlog(object):
    """parses the raptor logs and separates the info out into HTML and XML logs for writing to diamonds
    and other logs"""
    def initialize(self, logFile):
        """Initialize helium log filter"""
    #try:
        self.scan_config = {}
        self.component_level_messages = {}
        self.error_level_counts = {}
        self.inReceipe = False
        self.logContents = ""
        self.logFileName = logFile
        self.startTagCompileObject = re.compile(START_TAG_REG_EX);
        self.endTagCompileObject = re.compile(END_TAG_REG_EX);
        self.ignoreTextCompileObject = re.compile(IGNORE_TEXT_REG_EX);
        self.startRecording = False
        self.inReceipe = False
        self.logContents = ""
        self.lineNumber = 0
        self.startLineNumber = 0
        self.start_time = datetime.datetime.now()
        for category in DEFAULT_CONFIGURATION.keys():
            self.scan_config[category] = []
            self.error_level_counts[category.lower()] = 0

            for rule in DEFAULT_CONFIGURATION[category]:
                self.scan_config[category].append(re.compile(rule))
                
        self.logName = str(self.logFileName) + ".xml"
        self.loggerout = open(str(self.logFileName),"w")
        print "logName: %s\n" % self.logName
        #self.out = open(str(self.logFileName), "w")
        self.outxml = open(self.logName, "w")
        self.scanlogName = str(self.logFileName) +".scan2.html"
        self.logger = XMLGenerator(self.outxml, 'utf-8')
        self.logger.startDocument()
        empty_attrs = AttributesNSImpl({}, {})
        filename_attrs = {
            (None, u'filename'): str(self.logFileName) ,
        }
        filename_qnames = {
            (None, u'filename'): u'filename',
        }
        attrs = AttributesNSImpl(filename_attrs, filename_qnames)
        self.logger.startElementNS((None, u'log'), u'log', attrs)
        self.logger.characters("\n")
        self.logger.startElementNS((None, u'build'), u'build', empty_attrs)
        self.logger.characters("\n")
        return True
    #except:
        #self.out = None
        #sys.stderr.write("%s : error: cannot write log %s\n" %\
        #    (str(raptor.name), self.logFileName.GetShellPath()))
        #return False

    def open(self, logFile):
        self.logFileName = logFile
        self.initialize(logFile)
        
        
    def write(self, text):
        """ callback function which is to process the logs"""
        for textLine in text.splitlines():
            if(self.ignoreTextCompileObject.search(textLine)):
                continue

            self.lineNumber += 1
            if(self.startTagCompileObject.search(textLine) != None):
                self.logContents = ""
                self.startRecording = True
                self.startLineNumber =  self.lineNumber
    
            if(self.endTagCompileObject.search(textLine)!= None):
                self.logContents += textLine + "\n"
                self.startRecording = False
                try:
                    self.parseContents()
                except:
                    print " error during helium log parsing"
                    print self.logContents
                
            self.loggerout.write(textLine + "\n")
            if self.startRecording:
                self.logContents += textLine + "\n"
            else:
                error_level = find_priority(textLine, self.scan_config)
                if(error_level != 'stdout'):
                    if DEFAULT_STRING not in self.component_level_messages:
                        self.component_level_messages[DEFAULT_STRING] = {}
                        for error_level in self.scan_config.keys():
                            self.component_level_messages[DEFAULT_STRING][error_level.lower()] = []
                    self.component_level_messages[DEFAULT_STRING][error_level.lower()].append("%s : line-number: %d " % 
                        (textLine, self.lineNumber))
                    self.error_level_counts[error_level.lower()] +=1
        return True

    def parseContents(self):
        """ Parse the contents within the tag, check if the errors within the tag is 
        matching the error list, using minidom.
        """        
        doc = parseString((self.logContents))
        for node in doc.childNodes:
            if (node.nodeType == node.ELEMENT_NODE):
                if(node.tagName == "recipe"):
                    component_name = node.getAttribute("bldinf")
                    self.process_output(component_name)
                elif(node.tagName == "warning" or node.tagName == "error"):
                    self.error_level_counts[node.tagName] += 1
                    if DEFAULT_STRING not in self.component_level_messages:
                        self.component_level_messages[DEFAULT_STRING] = {}
                        for error_level in self.scan_config.keys():
                            self.component_level_messages[DEFAULT_STRING][error_level.lower()] = []
                    self.component_level_messages[DEFAULT_STRING][str(node.tagName.lower())].append(
                    "%s : line-number: %d" % 
                    (getText(node.childNodes), self.lineNumber))
                    

    def writeToXMLFile(self):
        """ Writes the log output to diamonds understandable xml format."""
        try:
            components_size = (len(self.component_level_messages.keys()))
            if(components_size > 0):
                for component_name in self.component_level_messages.keys():
                    name_attr = {
                        (None, u'name'): component_name,
                    }
                    name_attr_qnames = {
                        (None, u'name'): u'name',
                    }
                    name_attrs = AttributesNSImpl(name_attr, name_attr_qnames)
                    self.logger.startElementNS((None, u'task'), u'task', name_attrs)
                    for err_level in self.component_level_messages[component_name].keys():
                        message_attr = {
                        (None, u'priority'): err_level,
                        }
                        message_attr_qnames = {
                            (None, u'priority'): u'priority',
                        }
                        for err in self.component_level_messages[component_name][err_level.lower()]:
                            message_attrs = AttributesNSImpl(message_attr, message_attr_qnames)
                            self.logger.characters("\n")
                            self.logger.characters("  ")
                            self.logger.startElementNS((None, u'message'), u'message', message_attrs)
                            self.logger.characters(err)
                            self.logger.endElementNS((None, u'message'), u'message')
                            #self.out.write(err)
    
                    self.logger.characters("\n")
                    self.logger.endElementNS((None, u'task'), u'task')
                    self.logger.characters("\n")
        
        except:
            print " error during writing log xml"
                
        
    def process_output(self, component_name):
        """ Process the log output for errors and stores it in dictionary"""    
        #self.component_level_messages.clear()
        count = 0
        for line in self.logContents.splitlines():
            error_level = find_priority(line, self.scan_config)
            if component_name not in self.component_level_messages:
                self.component_level_messages[component_name] = {}
                for error_level in self.scan_config.keys():
                    self.component_level_messages[component_name][error_level.lower()] = []
            if(error_level != 'stdout'):
                if(error_level not in self.component_level_messages[component_name]):
                    self.component_level_messages[component_name][error_level.lower()] = []
                self.component_level_messages[component_name][error_level.lower()].append(
                "%s : line-number: %d" % 
                    ((line, self.startLineNumber + count)))
                self.error_level_counts[error_level.lower()] +=1
            count += 1

    def summary(self):
        """Writes finally the logs in xml format using SAX and creates the scanlog"""
        self.writeToXMLFile()
        self.end_time = datetime.datetime.now()
        total_time = self.end_time - self.start_time
        create_scanlog(self.component_level_messages, self.logName, self.scanlogName, 
            self.error_level_counts,total_time)
        return True

    def close(self):
        """Close the log file"""

        try:
            self.logger.endElementNS((None, u'build'), u'build')
            self.logger.endElementNS((None, u'log'), u'log')
            #self.logger.close()
            self.loggerout.close()
            self.outxml.close()
            #self.scanlogName.close()
            return True
        except:
            return False

def create_scanlog(components_level_messages, logname, outname, error_level_counts, total_time):
    """
    Converting the output to Helium log html scanlog format.
    """

    fh = codecs.open(outname, 'w+', 'utf8')
    html = """<html>
    <head><title>%s</title></head>
    <body>
    <h2>Overall</h2>
    <table border="1" cellpadding="0" cellspacing="0" width="100%%">
    <tr>
        <th width="22%%">&nbsp;</th>
        <th width="12%%">Time</th>
        <th width="12%%">Errors</th>
        <th width="12%%">Warnings</th>
        <th width="12%%">Critical</th>
        <th width="30%%">Migration Notes</th>
    </tr>
    <tr>""" % ( os.path.basename(logname))
    html += "<td width=\"22%%\">Total</td>"
    html += "<td width=\"12%%\" align=\"center\">%s</td>" % time.strftime("%H:%M:%S", time.gmtime(total_time.seconds))
    def add_err_count(error_level, count):
        color = {'error': 'FF0000', 'warning': 'FFF000', 'critical': 'FF7000', 'remark': '0000FF', 'info': 'FFFFFF'}
        if error_level.lower() in color:
            if count > 0:
                if error_level == 'error':
                    return "<td width=\"12%%\" align=\"center\" bgcolor=\"%s\">%d</td>" % (color[error_level], count)
                else:
                    return "<td align=\"center\" bgcolor=\"%s\">%d</td>" % (color[error_level], count)
            return "<td align=\"center\">%s</td>" % count
    html += add_err_count('error', error_level_counts['error'] )
    html += add_err_count('warning', error_level_counts['warning'])
    html += add_err_count('critical', error_level_counts['critical'])
    html += add_err_count('info', error_level_counts['info'])
    html += """</tr></table>
    <h1>%s</h1>
    <h2>By Component</h2>
        <table border=\"1\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%%\">
            <tr>
                <th width=\"55%%\">Component</th>
                <th width=\"15%%\">Errors</th>
                <th width=\"15%%\">Warnings</th>
                <th width=\"15%%\">Criticals</th>
                <th width=\"15%%\">Notes</th>
            </tr>""" % ( os.path.basename(logname))
        
    cid = 0
    for component_name in components_level_messages.keys():
        html += "<tr>"
        html += "<td>%s</td>" % component_name
        def add_category(error_level):
            color = {'error': 'FF0000', 'critical': 'FF7000', 'warning': 'FFF000', 'remark': '0000FF', 'info': 'FFFFFF'}
            val = len(components_level_messages[component_name][error_level])
            if val > 0:
                if error_level == 'error':
                    return "<td align=\"center\" bgcolor=\"%s\"><a href=\"#section%s\">%s</a></td>" % (color[error_level], cid, val)
                else:
                    return "<td align=\"center\" bgcolor=\"%s\">%s</td>" % (color[error_level], val)
            return "<td align=\"center\">%s</td>" % val
        html += add_category('error')     
        html += add_category('warning')
        html += add_category('critical')     
        html += add_category('info')
        html += "</tr>"
        cid += 1
    html += "</table>"
    cid = 0
    html += "<h2>Error Details by Component</h2>"
    fh.write(html.encode('utf8'))
    for component_name in components_level_messages.keys():
        html = "<h3><a name=\"section%s\">%s</a></h3>" % (cid, component_name)
        def add_dump(cat):
            """ adds the list of errors of the build """
            out = ""
            if ( components_level_messages[component_name][cat]):
                out = "<h1>%s</h1>" % (cat)
            for line in components_level_messages[component_name][cat]:
                out += line + "<br/>"
            return out
        html += add_dump('error')     
        html += add_dump('warning')     
        html += add_dump('critical')     
        html += add_dump('info')     
        fh.write(html.encode('utf8'))
        cid += 1
    html = """
<body>
</html>
    """
    fh.write(html.encode('utf8'))
    fh.close()

if __name__ == "__main__":

    """ standalone app """
    cli = OptionParser(usage="%prog [options]")
    cli.add_option("--log", help="Raptor log file")
    cli.add_option("--output", help="Raptor log file")
                   
    opts, dummy_args = cli.parse_args()
    if not opts.log:
        cli.print_help()
        sys.exit(-1)

    filter = SBSScanlog()
    filter.open(opts.output)

    logFile = open(opts.log, 'r')

    for line in logFile:
        filter.write(line)

    filter.summary()
    filter.close() 