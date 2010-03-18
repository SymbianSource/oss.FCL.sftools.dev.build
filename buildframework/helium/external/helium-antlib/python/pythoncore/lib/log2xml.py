#============================================================================ 
#Name        : log2xml.py 
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

""" Symbian log converter.
"""
import xml.dom.minidom
import sys
import os
import re
import shutil
import codecs
import time
import datetime
from xml.sax import make_parser 
from xml.sax.handler import ContentHandler 
from xml.sax.saxutils import escape


DEFAULT_CONFIGURATION = {"FATAL": [r"mingw_make.exe"],
                         "ERROR": [r'^(?:(?:\s*\d+\)\s*)|(?:\s*\*\*\*\s*))ERROR:',
                                   r"^MISSING:",
                                   r"Error:\s+",
                                   r"^Error:",
                                   r"'.+' is not recognized as an internal or external command",
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
                                   r"^ERROR\t",
                                   r"syntax error at line",],
                         "CRITICAL": [r"[Ww]arning:?\s+(#111-D|#1166-D|#117-D|#128-D|#1293-D|#1441-D|#170-D|#174-D|#175-D|#185-D|#186-D|#223-D|#231-D|#257-D|#284-D|#368-D|#414-D|#430-D|#47-D|#514-D|#546-D|#68-D|#69-D|#830-D|#940-D|#836-D|A1495E|L6318W|C2874W|C4127|C4355|C4530|C4702|C4786|LNK4049)"],
                         "WARNING": [r'\): Missing file:',
                                      r'^(\d+\))?\s*WARNING:', r'^MAKEDEF WARNING:',
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
    keys = config.keys()
    keys.reverse()    
    for category in keys:
        for rule in config[category]:
            if rule.search(line) != None:
                return category.lower()
    return "stdout"

class Stack:
    """ Bottomless stack. If empty just pop a default element. """
    
    def __init__(self, default):
        self.__default = default
        self.__stack = []
  
    def pop(self):
        result = None
        try:
            result = self.__stack.pop()
        except IndexError, e:
            result = self.__default
        return result
  
    def push(self, item):
        self.__stack.append(item)
  
    def __len__(self):
        return len(self.__stack)

def to_cdata(text):
    """ Cleanup string to match CDATA requiements.
        These are the only allowed characters: #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF].
    """
    result = ""
    for c in list(text):
        v = ord(c)        
        if v == 0x9 or v == 0xa or v == 0xd:
            result += c
        elif v>=0x20 and v <= 0xd7ff:
            result += c
        elif v>=0xe000 and v <= 0xfffd:
            result += c
        elif v>=0x10000 and v <= 0x10ffff:
            result += c
        else:
            result += " " 
    return result

class LogWriter(object):
    """ XML Log writer. """
    
    def __init__(self, stream, filename):
        self.__stream = stream
        self.__stream.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
        self.__stream.write("<log filename=\"%s\">\n" % filename)
        self.__stream.write("\t<build>\n")
        self.__indent = "\t"
        self.__intask = 0

    def close(self):
        # closing open tasks...
        while self.__intask > 0:
            self.close_task()
        self.__stream.write("\t</build>\n")
        self.__stream.write("</log>\n")
        self.__stream.close()

    def open_task(self, name):
        self.__indent += "\t"
        self.__intask += 1
        self.__stream.write("%s<task name=\"%s\">\n" % (self.__indent, name))

    def close_task(self):
        if self.__intask > 0:
            self.__intask -= 1
            self.__stream.write("%s</task>\n" % (self.__indent))
            self.__indent = self.__indent[:-1]
    
    def message(self, priority, msg):
        try:
            acdata = to_cdata(msg.decode('utf-8', 'ignore'))
            self.__stream.write("%s<message priority=\"%s\"><![CDATA[%s]]></message>\n" % (self.__indent+"\t", priority, acdata))
        except UnicodeDecodeError, e:
            print e
        


def convert(inputfile, outputfile, fulllogging=True, configuration=DEFAULT_CONFIGURATION):
    """ Convert an input log into an XML log and write an outputfile. """
    
    # Compiling the regexp  
    built_config = {}
    for category in configuration.keys():
        built_config[category] = []
        for rule in configuration[category]:
            built_config[category].append(re.compile(rule))
    
    # Generating the XML log
    log = open(inputfile, 'r')
    olog = codecs.open(outputfile, 'w+', 'utf-8', errors='ignore')
    xmllog = LogWriter(olog, inputfile)

    
    match_finnished = re.compile(r"^===\s+.+\s+finished") 
    match_started = re.compile(r"^===\s+(.+)\s+started") 
    match_component = re.compile(r"^===\s+(.+?)\s+==\s+(.+)")
    match_logger_component = re.compile(r'^\s*\[.+?\]\s*')
    #match_ant_target_start = re.compile(r'.*INFO\s+-\s+Target\s+####\s+(.+)\s+####\s+has\s+started')
    #match_ant_target_end = re.compile(r'.*INFO\s+-\s+Target\s+####\s+(.+)\s+####\s+has\s+finnished')
    match_ant_target_start = re.compile(r'^([^\s=\[\]]+):$')
    match_ant_target_end = re.compile(r'^([^\s=]+):\s+duration')
    symbian = False
    ant_has_open_task = False
    # looping
    for line in log:
                
        # matching Ant logging
        if not symbian and match_ant_target_end.match(line):
            xmllog.close_task()
            ant_has_open_task = False
            continue
        elif not symbian and match_ant_target_start.match(line):
            result = match_ant_target_start.match(line)
            if result != None:
                if ant_has_open_task:
                    xmllog.close_task()
                    ant_has_open_task = False
                xmllog.open_task(result.group(1))
                ant_has_open_task = True
            continue
        # matching Symbian logging
        line = match_logger_component.sub(r'', line)
        line = line.strip()
        if line.startswith("++ Finished at"):
            xmllog.close_task()
        elif line.startswith("=== "):
            if match_finnished.match(line):
                xmllog.close_task()
            else:
                # This is a symbian log
                symbian = True
                result = match_component.match(line)
                if result != None:
                    xmllog.open_task(result.group(2))
                # === cenrep_s60_32 started
                result = match_started.match(line)
                if result != None:
                    xmllog.open_task(result.group(1))
        else:
            # Type?
            priority = find_priority(line, built_config)
            if (fulllogging or priority != 'stdout'):
                xmllog.message(priority, line)
    # end file
    xmllog.close()
    
def convert_old(inputfile, outputfile, fulllogging=True, configuration=DEFAULT_CONFIGURATION):
    """ Convert an input log into an XML log and write an outputfile. """
    
    # Compiling the regexp  
    built_config = {}
    for category in configuration.keys():
        built_config[category] = []
        for rule in configuration[category]:
            built_config[category].append(re.compile(rule))
    
    # Generating the XML log
    log = open (inputfile, 'r')
    doc = xml.dom.minidom.Document()
    root = doc.createElementNS("", "log")
    root.setAttributeNS("", "name", inputfile)
    doc.appendChild(root)
    build = doc.createElementNS("", "build")
    root.appendChild(build)
    # current group/task
    current = build
    # bottomless stask, if losing sync all message will be at top level.
    stack = Stack(build)
    
    match_finnished = re.compile(r"^===\s+.+\s+finished") 
    match_started = re.compile(r"===\s+(.+)\s+started") 
    match_component = re.compile(r"^===\s+(.+?)\s+==\s+(.+)")
    match_logger_component = re.compile(r'^\s*\[.+?\]\s*')
    #match_ant_target_start = re.compile(r'.*INFO\s+-\s+Target\s+####\s+(.+)\s+####\s+has\s+started')
    #match_ant_target_end = re.compile(r'.*INFO\s+-\s+Target\s+####\s+(.+)\s+####\s+has\s+finnished')
    match_ant_target_start = re.compile(r'^([^\s=]+):$')
    match_ant_target_end = re.compile(r'^([^\s=]+):\s+duration')
    # looping
    for line in log:
                
        # matching Ant logging
        if match_ant_target_end.match(line):
            current = stack.pop()
            continue
        elif match_ant_target_start.match(line):
            result = match_ant_target_start.match(line)
            if result != None:
                stack.push(current)
                task = doc.createElementNS("", "task")
                task.setAttributeNS("", "name", result.group(1))
                current.appendChild(task)
                current = task
            continue
        # matching Symbian logging
        line = match_logger_component.sub(r'', line)
        line = line.strip()
        if line.startswith("++ Finished at"):
            current = stack.pop()
        elif line.startswith("==="):
            if match_finnished.match(line):
                current = stack.pop()
            else:
                result = match_component.match(line)
                if result != None:
                    stack.push(current)
                    task = doc.createElementNS("", "task")
                    task.setAttributeNS("", "name", result.group(2))
                    current.appendChild(task)
                    current = task
                # === cenrep_s60_32 started
                result = match_started.match(line)
                if result != None:
                    task = doc.createElementNS("", "task")
                    task.setAttributeNS("", "name", result.group(1))
                    stack.push(current)
                    current.appendChild(task)
                    current = task
        else:
            msg = doc.createElementNS("", "message")
            # Type?
            priority = find_priority(line, built_config)
            if (fulllogging or priority != 'stdout'):
                msg.setAttributeNS("", "priority", priority)
                msg.appendChild(doc.createCDATASection(to_cdata(line.decode("utf-8"))))
                current.appendChild(msg)
        
    file_object = codecs.open(outputfile, 'w', "utf_8")
    file_object.write(doc.toprettyxml())
    file_object.close()

class ContentWriter(ContentHandler):
    """ SAX Content writer. Parse and write an XML file. """
    def __init__(self, os, indent=""):
        self.os = os
        self.indent = indent
        self.__content = u""
    
    def startElement(self, name, attrs):
        self.os.write(self.indent + "<" + name)        
        if attrs.getLength() > 0:
            self.os.write(" ")        
        self.os.write(" ".join(map(lambda x: "%s=\"%s\"" % (x, attrs.getValue(x)), attrs.getNames())))            
        self.os.write(">\n")
        self.indent += "\t"
        self.__content = ""
    
    def endElement(self, name):
        if len(self.__content) > 0:
            self.os.write(self.indent + self.__content + "\n")                
        self.indent = self.indent[:-1]
        self.os.write("%s</%s>\n" % (self.indent, name))
        self.__content = ""
        
    def characters(self, content):        
        self.__content += unicode(escape(content.strip()))

class AppendSummary(ContentWriter):
    """ SAX content handler to add an XML log to the summary. """
    def __init__(self, output, xmllog):
        ContentWriter.__init__(self, output)
        self.xmllog = xmllog

    def startDocument(self):
        self.os.write('<?xml version="1.0" encoding="utf-8"?>\n')
    
    def startElement(self, name, attrs):
        ContentWriter.startElement(self, name, attrs)
        if name == "logSummary":
            parser = make_parser()
            parser.setContentHandler(ContentWriter(self.os, self.indent))
            parser.parse(open(self.xmllog, 'r'))
    

def append_summary(summary, xmllog, maxmb=80):
    """ Append content to the summary xml file. """
    if os.path.getsize(summary) + os.path.getsize(xmllog) > (maxmb*1024*1024):
        print 'Error: ' + summary + ' larger than ' + str(maxmb) + 'MB, not appending'
        return
    
    outfile = codecs.open(summary + ".tmp", 'w', "utf8")
    parser = make_parser()
    parser.setContentHandler(AppendSummary(outfile, xmllog))
    
    input = open(summary, 'r')
    parser.parse(input)
    input.close()
    outfile.close()
    # Updating the summary file.
    os.unlink(summary)
    os.rename(summary + ".tmp", summary)    
    

def symbian_log_header(output, config, command, dir):
    output.log("===-------------------------------------------------")
    output.log("=== %s" % config)
    output.log("===-------------------------------------------------")
    output.log("=== %s started %s" % (config, datetime.datetime.now().ctime()))
    output.log("=== %s == %s" % (config, dir))
    output.log("-- %s" % command)
    output.log("++ Started at %s" % datetime.datetime.now().ctime())
    output.log("+++ HiRes Start %f" % time.time())
    output.log("Chdir %s" % dir)
    

def symbian_log_footer(output):
    output.log("+++ HiRes End %f" % time.time())
    output.log("++ Finished at %s" % datetime.datetime.now().ctime())
    
    
if __name__ == "__main__":
    convert(sys.argv[1], "%s.xml" % sys.argv[1], fulllogging=False)
    """ An empty summary:
        <?xml version=\"1.0\" encoding=\"UTF-8\"?><logSummary/>
    """
    #s = open(r"z:\summary.xml", "w")
    #s.write("""<?xml version=\"1.0\" encoding=\"UTF-8\"?><logSummary/>""")
    #s.close()
    #append_summary(r'Z:\summary.xml', r'Z:\output\logs\test_0.0.1.mc_5132_2_build.log2.xml')
    #append_summary(r'Z:\summary.xml', r'Z:\output\logs\test_0.0.1_BOM.xml')
    
    