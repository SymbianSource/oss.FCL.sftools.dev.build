#============================================================================ 
#Name        : CreateZipInput.py 
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

""" Script that generate makefile for single archiving configuration. """
import os
import tempfile
# setting the egg cache directory to a pid specific location.
# this should prevent issues with concurrent threads.
if not os.environ.has_key('PYTHON_EGG_CACHE') or os.environ['PYTHON_EGG_CACHE'] == None: 
    os.environ['PYTHON_EGG_CACHE'] = tempfile.gettempdir() + "/" + str(os.getpid())

import configuration
import archive
import logging
import sys
from optparse import OptionParser

_logger = logging.getLogger('CreateZipInput')
_logger.setLevel(logging.INFO)

def main():
    """ The application main. """
    cli = OptionParser(usage="%prog [options]")
    cli.add_option("--filename", help="Configuration file") 
    cli.add_option("--config", help="Config to load (spec name).")
    cli.add_option("--id", help="Config number to execute", type="int")
    cli.add_option("--output", help="Output file")
    cli.add_option("--writertype", help="Writer Type")
                   
    opts, dummy_args = cli.parse_args()
    if not opts.filename:
        cli.print_help()
        sys.exit(-1)
    if not opts.config:
        cli.print_help()
        sys.exit(-2)
    if opts.id == None:
        cli.print_help()
        sys.exit(-3)
    if not opts.output:
        cli.print_help()
        sys.exit(-4)
    if not opts.writertype:
        cli.print_help()
        sys.exit(-5)

    _logger.info("Loading %s..." % opts.filename) 
    builder = configuration.NestedConfigurationBuilder(open(opts.filename, 'r'))
    configset = builder.getConfiguration()
    _logger.info("Getting %s..." % opts.config)
    configs = configset.getConfigurations(opts.config)

    if len(configs) > 0 and int(opts.id) >= 0 and int(opts.id) < len(configs):
        _logger.info("Generating %s.%s as %s..." % (opts.config, opts.id, opts.output))
        prebuilder = archive.ArchivePreBuilder(configuration.ConfigurationSet(configs), opts.config, opts.writertype, int(opts.id))
        prebuilder.write(opts.output)

if __name__ == "__main__":
    main()