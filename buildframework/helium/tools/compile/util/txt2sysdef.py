#============================================================================ 
#Name        : txt2sysdef.py 
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
import os.path
import sys
import shutil
import string


if __name__ == "__main__":
    argc = len(sys.argv)
    if argc >= 4 or argc < 2:
        print 'Simple tool for one-time converting txt-files to SystemDefinitions'
        print 'remeber to manually edit the outputs'
        print 'usage:', sys.argv[0], 'infile [outfile] '
        sys.exit(1)


    filename = sys.argv[1]

    if argc == 3:
        filename2 =  sys.argv[2]
    else:
        filename2, ext = os.path.splitext(filename)
        filename2 += ".xml"
    print "outfilename is %s" % filename2

    


    file = open (filename,"r")
    global DATA
    DATA = file.readlines()

    try:
        shutil.copyfile("dtd.xml", filename2)
    except:
        pass
    
    outfile = open(filename2,"a")
    component = ""
    compname = ""
    bld_path = ""
    
    outfile.write('<SystemDefinition name="SystemModel" schema="1.4.0">\n')
    outfile.write('  <systemModel>\n')
    outfile.write('<layer name="%s">\n' % os.path.basename(filename))


    #print DATA
    for line in DATA:
        # ignore outcommented lines in input 
        if '#Components' in line:
            continue
        if 'Component' in line:
            try:
                # we are expecting lines "Component /path/to/named/group componentName"
                component, bldpath, comname =  line.split()
                print ("prosessing component %s \n" % comname.strip())
                outfile.write('<unit unitID="%s_%s"  name="%s" bldFile="%s" mrp=""/> \n' % 
                              (os.path.basename(filename), comname.strip(), comname.strip(), bldpath.strip()))
            except:
                print ("Problems with Line:\n %s\n" % line)


    print "finishing"
    outfile.write('</component> \n')
    outfile.write('</module> \n')
    outfile.write('    </layer>\n')
    
    outfile.write('  </systemModel>\n')
    outfile.write('</SystemDefinition>\n')

    outfile.close()    
