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

def main():
    if len(sys.argv) != 3:
        print "Usage: icf2txt.py bom.xml out.txt"
        sys.exit(1)

    bomxmlFile = open(sys.argv[1], "r")
    outFile = open(sys.argv[2], "w")
    
    bomxml = amara.parse(bomxmlFile)
    
    if hasattr(bomxml.bom.content.project, "icf"):
        for icf in bomxml.bom.content.project.icf:
            outFile.write(str(icf) + "\n")

    outFile.close()
    bomxmlFile.close()

if __name__ == "__main__":
    main()