#============================================================================ 
#Name        : ini2sysdef.py 
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
import shutil
import string


if __name__ == "__main__":
    argc = len(sys.argv)
    if argc >= 4 or argc < 2:
        print 'Simple tool for one-time converting ini-files to SystemDefinitions'
        print 'remeber to manually edit the outputs'
        print 'usage:', sys.argv[0], 'infile [outfile] '
        sys.exit(1)


    filename = sys.argv[1]
##    r"C:\USERS\work\systemdefinitionXML\spp_config\build\spp_convcom.ini"
    if argc == 3:
        filename2 =  sys.argv[2]
    else:
        filename2, ext = os.path.splitext(filename)
        filename2 += ".xml"
    print "outfilename is %s" % filename2

    

    ##r"C:\USERS\work\systemdefinitionXML\spp_config\build\spp_convcom.xml"
    #filename = "logparse_rules.txt"

    file = open (filename,"r")
    global DATA
    DATA = file.readlines()

    try:
        shutil.copyfile("spp_dtd.xml", filename2)
    except:
        pass
    
    outfile = open(filename2,"a")
    component = ""
    compname = ""
    bld_path = ""
    
    outfile.write('<SystemDefinition name="spp_SystemModel" schema="1.4.0">\n')
    outfile.write('  <systemModel>\n')
    outfile.write('<layer name="%s">\n' % filename)
    outfile.write('  <logicalset name="%s">\n'   % filename)


    #print DATA
    for line in DATA:
        if '[' in line:
            if not component == "":
                #the first one
                outfile.write('</component> \n')
                outfile.write('</module> \n')
            component = line.split('[')[1].split(']')[0]
            print "we have component here : ",  component

            outfile.write('<module name="%s"> \n' % component.strip())
        if "name" in line:
            compname = line.split('=')[1]
#            print "we have  name here : ",  compname
            outfile.write('<component name="%s"> \n' % compname.strip())
        if "bld_path" in line:
            bldpath = line.split('=')[1]
            bldpath = bldpath.strip()
            bldpath = bldpath.strip('\\')
            bldpath = bldpath.replace('<', '')
            bldpath = bldpath.replace('>', '')
            
            
            
#            print "we have path here : ",  bldpath
            outfile.write('<unit unitID="%s_%s"  name="%s" bldFile="%s" mrp=""/> \n' % 
                          (os.path.basename(filename), component.strip(), compname.strip(), bldpath.strip()))



    print "finishing"
    outfile.write('</component> \n')
    outfile.write('</module> \n')
    outfile.write('    </logicalset>\n')
    outfile.write('    </layer>\n')
    
    outfile.write('  </systemModel>\n')
    outfile.write('</SystemDefinition>\n')


    
    outfile.close()    
