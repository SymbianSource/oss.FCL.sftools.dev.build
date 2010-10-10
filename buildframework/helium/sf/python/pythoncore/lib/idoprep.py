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
_logger = logging.getLogger("check_latest_release")
            
def get_s60_env_details(server, service, product, release, rev, cachefilename, checkmd5, usetickler):
    """ Return s60 environ details """
    revision = r'(_\d{3})?'
    if rev != None:
        revision = rev

    if cachefilename:
        _logger.info(str("Using cache file: %s" % cachefilename))
    
    checkmd5 = False
    if checkmd5 != None:
        checkmd5 = str(checkmd5).lower()
        checkmd5 = ((checkmd5 == "true") or (checkmd5 == "1") or (checkmd5 == "on"))
                
    branch = os.path.join(server, service, product)
    if not os.path.exists(branch):
        raise IOError("Error occurred: Could not find directory %s" % branch)
        
    result = []
    for rel in os.listdir(branch):
        relpath = os.path.join(branch, rel)
        _logger.info("Checking: %s" % str(relpath))
        res = re.match(r"%s%s$" % (release, revision), rel, re.I)
        if res != None:
            _logger.info("Found: %s" % str(relpath))
            result.append(relpath)
    result.sort(reverse=True)
    use_tickler = False
    tickler_validation = str(usetickler).lower()
    if tickler_validation != None:
        use_tickler = ((tickler_validation == "true") or (tickler_validation == "1"))
    validresults = []
    for rel in result:
        try:
            metadata_filename = symrec.find_latest_metadata(str(rel))
            if metadata_filename is not None and os.path.exists(metadata_filename):
                _logger.info(str("Validating: %s" % metadata_filename))
                if (use_tickler):
                    validator = symrec.ValidateTicklerReleaseMetadata(metadata_filename, cachefilename)
                else:
                    validator = symrec.ValidateReleaseMetadataCached(metadata_filename, cachefilename)
                if validator.is_valid(checkmd5):
                    _logger.info(str("%s is valid." % rel))
                    validresults.append(rel)
                    break
                else:
                    _logger.info(str("%s is not a valid release." % rel))
            elif metadata_filename is None:
                _logger.info(str("Could not find the release metadata file under %s" % rel))
        except IOError, exc:
            _logger.warning(str("WARNING: %s: %s" % (rel , exc)))
            _logger.warning(("%s is not a valid release." % rel))
            traceback.print_exc()
    
    result = validresults
    if len(result) == 0:
        raise EnvironmentError("Error finding release.")
    print result[0]
    return result
    
def get_version(buiddrive, resultname):
    """ Return s60 version """
    vfile = os.path.join(buiddrive + os.sep, 's60_version.txt')
    version = None
    if (os.path.exists(vfile)):
        _logger.info("Are we still up-to-date compare to %s" % str(vfile))
        f_file = open(str(vfile), 'r')
        version = f_file.readline()
        _logger.info(str("'%s' == '%s'" % (version, resultname)))
        f_file.close()
    else:
        _logger.info("Version file not found getting new environment...")
    return version
        
def create_ado_mapping(sysdefconfig, adomappingfile, qualityMapping, builddrive, adoqualitydirs):
    """ Creates ado mapping and ado quality mapping files """
    input_ = open(sysdefconfig, 'r')
    output = open(adomappingfile, 'w')
    print "ado mapping file: %s" % adomappingfile
    for sysdef in input_.readlines():
        sysdef = sysdef.strip()
        if len(sysdef) > 0:
            print "Checking %s" % sysdef
            os.path.dirname(sysdef)
            location = ido.get_sysdef_location(sysdef)
            if location != None:
                if os.sep == '\\':
                    sysdef = os.path.dirname(sysdef).replace('\\','/').replace(':','\\:')
                    component = os.path.normpath(os.path.join(builddrive, os.environ['EPOCROOT'], location)).replace('\\','/').replace(':','\\:')
                else:
                    sysdef = os.path.dirname(sysdef).replace('\\','/')
                    if location.startswith('/'):
                        component = os.path.normpath(os.path.join(builddrive, location.lstrip('/'))).replace('\\','/')
                    else:
                        component = os.path.normpath(os.path.join(builddrive, location)).replace('\\','/')
                print "%s=%s\n" % (sysdef, component)
                if adoqualitydirs == None or qualityMapping == 'false':
                    output.write("%s=%s\n" % (sysdef, component))
                else:
                    for dir_ in adoqualitydirs.split(','):
                        if os.path.normpath(dir_) == os.path.normpath(os.path.join(builddrive, os.environ['EPOCROOT'], location)):
                            output.write("%s=%s\n" % (sysdef, component))
    output.close()
    input_.close()