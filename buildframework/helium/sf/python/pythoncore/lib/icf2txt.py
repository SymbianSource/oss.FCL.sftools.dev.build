#============================================================================ 
#Name        : icf2txt.py 
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

import sys
import amara
import os

def get_icfs(filename):
    """ Read the list of icfs from the BOM. """
    result = []
    bomxmlFile = open(filename, "r")
    bomxml = amara.parse(bomxmlFile)
    if hasattr(bomxml.bom.content.project, "icf"):
        for icf in bomxml.bom.content.project.icf:
            result.append(str(icf))
    bomxmlFile.close()
    return result

def main():
    if len(sys.argv) != 3:
        print "Usage: icf2txt.py bom.xml out.txt"
        sys.exit(1)

    result = ['BOM not generated, the list of ICFs could not be generated']
    if os.path.exists(sys.argv[1]):
        result = get_icfs(sys.argv[1])

    outFile = open(sys.argv[2], "w")
    for icf in result:
        outFile.write(str(icf) + "\n")
    outFile.close()
    

if __name__ == "__main__":
    main()