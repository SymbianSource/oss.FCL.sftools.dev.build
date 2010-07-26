#============================================================================ 
#Name        : custom.py 
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

import ats3
import ats3.dropgenerator as adg
from optparse import OptionParser
from path import path # pylint: disable-msg=F0401
import logging
_logger = logging.getLogger('ats')

def create_drop(config):
    """Create a test drop."""
    test_plan = ats3.Ats3TestPlan(config)
    test_plan.set_plan_harness()
    flash_images = [path(p) for p in config.flash_images]
    test_plan.insert_set(image_files=flash_images)
    generator = adg.Ats3TemplateTestDropGenerator()
    _logger.info("generating drop file: %s" % config.drop_file)
    generator.generate(test_plan, output_file=config.drop_file, config_file=config.config_file)

def main():
    cli = OptionParser(usage="%prog [options]")
    cli.add_option("--device-type", help="Device type (e.g. 'PRODUCT')", default="unknown")
    cli.add_option("--diamonds-build-url", help="Diamonds build url", default='')
    cli.add_option("--drop-file", help="Name for the final drop zip file", default="ATS3Drop.zip")
    cli.add_option("--file-store", help="Destination path for reports.", default="")
    cli.add_option("--flash-images", help="Paths to the flash image files", default="")     
    cli.add_option("--report-email", help="Email notification receivers", default="")
    cli.add_option("--testrun-name", help="Name of the test run", default="run")
    cli.add_option("--config", help="Path to the config file", default="")
    cli.add_option("--test-timeout", help="Test execution timeout value (default: %default)", default="60")
    cli.add_option("--custom-template", help="Path to the ats template file")
    cli.add_option("--ats4-enabled", help="ATS4 enabled", default="True")
    cli.add_option("--verbose", help="Increase output verbosity", action="store_true", default=True)
    cli.add_option("--test-type", help="Name of test harness")
    opts, _ = cli.parse_args()
    
    if opts.verbose:
        _logger.setLevel(logging.DEBUG)
        logging.basicConfig(level=logging.DEBUG)
    
    config = ats3.Configuration(opts, [])
    create_drop(config)

if __name__ == "__main__":
    main()