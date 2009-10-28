#============================================================================ 
#Name        : ant.py 
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

""" Quality Ant task implementation. """
import integration.quality
import os
import traceback

def check_build_duplicates_task(project, task, attributes, elements):
    """ This is the implementation of the checkBuildDuplicatesMacro Ant task."""
    try:
        if attributes.get('output') == None:
            raise Exception("'output' attribute is not defined.")
        output = str(attributes.get('output'))
        task.log("Creating %s" % output)
        output = open(output, "w+")
        output.write("<?xml version=\"1.0\"?>\n<buildconflicts>\n")
        components_per_file = {}
        for eid in range(elements.get("fileset").size()):
            dirscanner = elements.get("fileset").get(int(eid)).getDirectoryScanner(project)
            dirscanner.scan()
            for jfilename in dirscanner.getIncludedFiles():
                filename = str(jfilename)
                task.log("Parsing %s" % filename)
                filename = os.path.join(str(dirscanner.getBasedir()), filename)
                parser = integration.quality.AbldWhatParser(open(filename, 'r'))
                parser.components_per_file = components_per_file
                parser.parse()
            
        for filename in components_per_file.keys():
            if len(components_per_file[filename]) > 1:
                output.write("    <file name=\"%s\">\n" % filename)
                output.write("".join(map(lambda x: "        <component name=\"%s\"/>\n" % x, components_per_file[filename])))
                output.write("    </file>\n")
        output.write("</buildconflicts>\n")
        output.close()
    except Exception, exc:
        task.log('ERROR: %s' % exc)
        traceback.print_exc()
        raise exc
