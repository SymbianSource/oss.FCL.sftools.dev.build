#============================================================================ 
#Name        : createlocales.py 
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

""" This script generate the locales_xx.iby files. """
import localisation
import sys

def main():
    """ Main function. """
    product = sys.argv[1]
    lid = sys.argv[2]
    extra_args = ""
    if len(sys.argv)>4:
        extra_args = " ".join(sys.argv[3:])
    try:
        extra_args = r'-include ..\include\oem\feature_settings.hrh -I. -I../../epoc32/rom/include ' + extra_args
        localisation.create_locales_iby(product, lid, [], '', extra_args)
    except Exception, exp:
        print exp
        sys.exit(-1)
    sys.exit(0)

if __name__ == "__main__":
    main()
