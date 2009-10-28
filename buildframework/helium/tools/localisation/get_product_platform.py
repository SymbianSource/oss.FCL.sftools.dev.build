#============================================================================ 
#Name        : get_product_platform.py 
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

""" return path for product from bsf data
"""
import bsf
import sys

def main():
    """ Main
    """
    product = sys.argv[1]
    
    bsfs = bsf.read_all()
    parents = bsfs[product].get_path_as_array()
    if len(parents) > 1:
        print parents[1]
        sys.exit(0) 
    sys.exit(-1)

if __name__ == "__main__":
    main()