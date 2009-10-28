#============================================================================ 
#Name        : sbs2logxml.py 
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

""" Temporary solution to extract raptor logs.
Should be replace by a log listenner when raptor will support it.
"""
import xml.sax
import xml.sax.handler
import xml.dom.minidom
import re
import codecs
import os
import sys
from optparse import OptionParser


DEFAULT_CONFIGURATION = {"FATAL": [r"mingw_make.exe"],
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
    keys = config.keys()
    keys.reverse()    
    for category in keys:
        for rule in config[category]:
            if rule.search(line) != None:
                return category.lower()
    return "stdout"


class SymbianLogHandler(xml.sax.handler.ContentHandler):
    def __init__ (self):
        xml.sax.handler.ContentHandler.__init__(self)
        self._in_recipe = False
        self._in_error = False
        self._in_warning = False
        self._recipe_status = None
        self._recipe_log = ""
        self._recipe_component = None
        self.errors = []
        self.warnings = []
        self.components = {}
        self.scan_config = {}
        for category in DEFAULT_CONFIGURATION.keys():
            self.scan_config[category] = []
            for rule in DEFAULT_CONFIGURATION[category]:
                self.scan_config[category].append(re.compile(rule))

    
    
    def startElement(self, name, attrs):
        if name == "recipe":
            self._in_recipe = True
            self._recipe_component = attrs.get('bldinf', None)
            if self._recipe_component not in self.components:
                self.components[self._recipe_component] = {}
                for cat in self.scan_config.keys():
                    self.components[self._recipe_component][cat.lower()] = []
            self._recipe_log = ""
            self._recipe_status = None
        elif name == "status" and self._in_recipe:
            self._recipe_status = attrs.get('exit', 'ok')
        elif name == "error":  
            self._in_error = True
            self._recipe_log = ""
        elif name == "warning":  
            self._in_warning = True
            self._recipe_log = ""
              
    def endElement(self, name):
        if name == "recipe":
            for line in self._recipe_log.splitlines():
                if not line.startswith('+ '):
                    priority = find_priority(line, self.scan_config)
                    if priority == "stdout":
                        continue
                    else:
                        self.components[self._recipe_component][priority].append(line)
            #if self._recipe_status == 'failed':
            #    self.components[self._recipe_component]['error'].append(self._recipe_log.strip())
            self._in_recipe = False
            self._recipe_log = ""
            self._recipe_status = None
            self._recipe_component = None
        elif name == "error":
            self.errors.append(self._recipe_log)  
            self._in_error = False
        elif name == "warning":
            self.warnings.append(self._recipe_log)
            self._in_warning = False
      
    def characters (self, ch):
        if self._in_recipe or self._in_error or self._in_warning:
            self._recipe_log += ch


def create_logxml(components, logname, outname):
    """
    Converting the output to Helium log xml format.
<?xml version="1.0" encoding="utf-8"?>
<log filename="K:\output\logs\ido_raptor_mcl_ipmsdo_MCL.52.61.s60_build_compile.log">
    <build>
        <task name="all">
            <message priority="warning"><![CDATA[E:/apps/sbs_2.2.0/win32/mingw/bin/cpp.exe: K:/s60/mw/ipappservices/rtp/rtpstack/group/RtpStpPacket.mmp:43:7: warning: extra tokens at end of #else directive]]></message>
    """
    impl = xml.dom.minidom.getDOMImplementation()

    xmllog = impl.createDocument(None, "log", None)
    root = xmllog.documentElement
    root.setAttribute('filename', logname)
    build = xmllog.createElement('build')
    root.appendChild(build)
    
    mtask = xmllog.createElement('task')
    mtask.setAttribute('name', os.path.basename(logname))
    build.appendChild(mtask)
    
    for cname in components.keys():
        task = xmllog.createElement('task')
        task.setAttribute('name', cname)
        mtask.appendChild(task)
        for category in components[cname].keys():
            for msg in components[cname][category]:
                msgnode = xmllog.createElement('message')
                msgnode.setAttribute('priority', category)
                msgnode.appendChild(xmllog.createCDATASection(msg))
                task.appendChild(msgnode)

    print "Writing %s" % outname
    fh = codecs.open(outname, 'w+', 'UTF-8')
    fh.write(xmllog.toprettyxml(encoding="UTF-8"))
    fh.close()

def create_scanlog(components, logname, outname):
    """
    Converting the output to Helium log html scanlog format.
<table border="1" cellpadding="0" cellspacing="0" width="100%">
<tr>
    <th width="55%">Component</th>
    <th width="15%">Errors</th>
    <th width="15%">Criticals</th>
    <th width="15%">Warnings</th>
    <th width="15%">Notes</th>
</tr>
    """

    html = """<html>
    <head><title>%s</title></head>
    <body>
    <h1>%s</h1>
    <h2>By Component</h2>
<table border="1" cellpadding="0" cellspacing="0" width="100%%">
<tr>
    <th width="55%%">Component</th>
    <th width="15%%">Errors</th>
    <th width="15%%">Criticals</th>
    <th width="15%%">Warnings</th>
    <th width="15%%">Notes</th>
</tr>""" % (os.path.basename(logname), os.path.basename(logname))
        
    cid = 0
    for cname in components.keys():
        html += "<tr>"
        html += "<td>%s</td>" % cname
        def add_category(cat):
            color = {'error': 'FF0000', 'critical': 'FF7000', 'warning': 'FFF000', 'remark': '0000FF', 'note': '000088'}
            val = len(components[cname][cat])
            if val > 0:
                if cat == 'error':
                    return "<td align=\"center\" bgcolor=\"%s\"><a href=\"#section%s\">%s</a></td>" % (color[cat], cid, val)
                else:
                    return "<td align=\"center\" bgcolor=\"%s\">%s</td>" % (color[cat], val)
            return "<td align=\"center\">%s</td>" % val
        html += add_category('error')     
        html += add_category('critical')     
        html += add_category('warning')     
        html += add_category('remark')     
        html += "</tr>"
        cid += 1
    html += "</table>"

    cid = 0
    html += "<h2>Error Details by Component</h2>"
    for cname in components.keys():
        html += "<h3><a name=\"section%s\">%s</a></h3>" % (cid, cname)
        def add_dump(cat):
            out = ""
            for line in components[cname][cat]:
                out += line + "<br/>"
            return out
        html += add_dump('error')
        cid += 1
        
    html += """
<body>
</html>
    """

    print "Writing %s" % outname
    fh = codecs.open(outname, 'w+', 'utf8')
    fh.write(html.encode('utf8'))
    fh.close()

if __name__ == "__main__":

    """ The application main. """
    cli = OptionParser(usage="%prog [options]")
    cli.add_option("--log", help="Raptor log file") 
    cli.add_option("--logxml", help="Logxml output file.")
    cli.add_option("--scanlog", help="HTML scanlog parsing")
                   
    opts, dummy_args = cli.parse_args()
    if not opts.log:
        cli.print_help()
        sys.exit(-1)
    
    #logname = 'log/ido_raptor_mcl_ipmsdo_MCL.52.61.s60_build_compile.log'
    parser = xml.sax.make_parser()   
    handler = SymbianLogHandler()
    parser.setContentHandler(handler)
    parser.parse(open(opts.log, 'r')) 

    # adding parsing issues
    components = handler.components.copy()
    components['raptor_parsing'] = {}
    for category in DEFAULT_CONFIGURATION.keys():
        components['raptor_parsing'][category.lower()] = []
    components['raptor_parsing']['error'] = handler.errors
    components['raptor_parsing']['warning'] = handler.warnings

    print "Summary:"
    print "%s\t%s%s%s%s" % ("Component".ljust(40), "Errors".ljust(10), "Criticals".ljust(10), "Warnings".ljust(10), "Remarks".ljust(10))
    for cname in components.keys():
        print "%s\t%s%s%s%s" % (cname.ljust(40), str(len(components[cname]['error'])).ljust(10),
                                             str(len(components[cname]['critical'])).ljust(10),
                                             str(len(components[cname]['warning'])).ljust(10),
                                             str(len(components[cname]['remark'])).ljust(10))

    if opts.logxml is not None:
        create_logxml(components, opts.log, opts.logxml)
    if opts.scanlog is not None:
        create_scanlog(components, opts.log, opts.scanlog)
