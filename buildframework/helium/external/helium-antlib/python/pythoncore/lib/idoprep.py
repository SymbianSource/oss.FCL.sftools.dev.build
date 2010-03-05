#============================================================================ 
#Name        : idoprep.py 
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

""" Modules related to ido-prep """

import re
import os
import symrec
import logging
import traceback
import ido

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("check_latest_release")

def validate(grace, service, product, release):
    """ Validate s60 grace server, s60 grace service, s60 grace product and 
        s60 grace release are set.
    """    
    if not grace:
        raise Exception("Property 's60.grace.server' is not defined.")
    if not service:
        raise Exception("Property 's60.grace.service' is not defined.")
    if not product:
        raise Exception("Property 's60.grace.product' is not defined.")
    if not release:
        raise Exception("Property 's60.grace.release' is not defined.")
            
def get_s60_env_details(grace, service, product, release, rev, cachefilename, s60gracecheckmd5, s60graceusetickler):
    """ Return s60 environ details """
    validate(grace, service, product, release)
    revision = r'(_\d{3})?'
    if rev != None:
        revision = rev

    if cachefilename:
        logger.info(str("Using cache file: %s" % cachefilename))
    
    checkmd5 = False
    if s60gracecheckmd5 != None:
        checkmd5 = str(s60gracecheckmd5).lower()
        checkmd5 = ((checkmd5 == "true") or (checkmd5 == "1") or (checkmd5 == "on"))
                
    branch = os.path.join(grace, service, product)
    if not os.path.exists(branch):
        raise Exception("Error occurred: Could not find directory %s" % branch)
        
    result = []
    for rel in os.listdir(branch):
        relpath = os.path.join(branch, rel)
        logger.info("Checking: %s" % str(relpath))
        res = re.match(r"%s%s$" % (release, revision), rel, re.I)
        if res != None:
            logger.info("Found: %s" % str(relpath))
            result.append(relpath)
    result.sort(reverse=True)
    use_tickler = False
    tickler_validation = str(s60graceusetickler).lower()
    if tickler_validation != None:
        use_tickler = ((tickler_validation == "true") or (tickler_validation == "1"))
    validresults = []
    for rel in result:
        try:
            metadata_filename = symrec.find_latest_metadata(str(rel))
            if metadata_filename is not None and os.path.exists(metadata_filename):
                logger.info(str("Validating: %s" % metadata_filename))
                if (use_tickler):
                    validator = symrec.ValidateTicklerReleaseMetadata(metadata_filename, cachefilename)
                else:
                    validator = symrec.ValidateReleaseMetadataCached(metadata_filename, cachefilename)
                if validator.is_valid(checkmd5):
                    logger.info(str("%s is valid." % rel))
                    validresults.append(rel)
                    break
                else:
                    logger.info(str("%s is not a valid release." % rel))
            elif metadata_filename is None:
                logger.info(str("Could not find the release metadata file under %s" % rel))
        except Exception, e:
            logger.warning(str("WARNING: %s: %s" % (rel , e)))
            logger.warning(("%s is not a valid release." % rel))
            traceback.print_exc()
    
    result = validresults
    if len(result) == 0:
        raise Exception("Error finding GRACE release.")
    print result[0]
    return result
    
def get_version(buiddrive, resultname):
    """ Return s60 version """
    vfile = os.path.join(buiddrive + os.sep, 's60_version.txt')
    version = None
    if (os.path.exists(vfile)):
        logger.info("Are we still up-to-date compare to %s" % str(vfile))
        f = open(str(vfile), 'r')
        version = f.readline()
        logger.info(str("'%s' == '%s'" % (version, resultname)))
        f.close()
    else:
        logger.info("Version file not found getting new environment...")
    return version
        
def create_ado_mapping(sysdefconfig, adomappingfile, adoqualitymappingfile, builddrive, adoqualitydirs):
    """ Creates ado mapping and ado quality mapping files """
    input = open(sysdefconfig, 'r')
    output = open(adomappingfile, 'w')
    outputquality = open(adoqualitymappingfile, 'w')
    components = {}
    for sysdef in input.readlines():
        sysdef = sysdef.strip()
        if len(sysdef) > 0:
            print "Checking %s" % sysdef
            os.path.dirname(sysdef)
            location = ido.get_sysdef_location(sysdef)
            if location != None:
                sysdef = os.path.dirname(sysdef).replace('\\','/').replace(':','\\:')
                component = os.path.normpath(os.path.join(builddrive, os.environ['EPOCROOT'], location)).replace('\\','/').replace(':','\\:')
                print "%s=%s\n" % (sysdef, component)
                output.write("%s=%s\n" % (sysdef, component))
                
                if adoqualitydirs == None:
                    outputquality.write("%s=%s\n" % (sysdef, component))
                else:
                    for dir in adoqualitydirs.split(','):
                        if os.path.normpath(dir) == os.path.normpath(os.path.join(builddrive, os.environ['EPOCROOT'], location)):
                            outputquality.write("%s=%s\n" % (sysdef, component))
    outputquality.close()
    output.close()
    input.close()


    
