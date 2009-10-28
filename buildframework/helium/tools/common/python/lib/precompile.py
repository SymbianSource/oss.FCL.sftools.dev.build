#============================================================================ 
#Name        : precompile.py 
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
import py_compile
import sys
from optparse import OptionParser

module_list = ['buildtools.py', 'CreateZipInput.py', 'fileutils.py', 'configuration.py', 'archive\\tools.py', 'archive\\selectors.py', 
				'archive\\scanners.py', 'archive\\mappers.py', 'archive\\builders.py', 'archive\\__init__.py' ]
def main():
    """ The application main. """
    cli = OptionParser(usage="%prog [options]")
    cli.add_option("--modulepath", help="input text to display") 
                   
    opts, dummy_args = cli.parse_args()
    if not opts.modulepath:
        cli.print_help()
        sys.exit(-1)
    
    for module in module_list:
        py_compile.compile(os.path.join(opts.modulepath, module))
    

if __name__ == "__main__":
    main()
