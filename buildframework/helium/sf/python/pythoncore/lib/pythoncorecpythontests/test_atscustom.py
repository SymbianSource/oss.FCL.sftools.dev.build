#============================================================================ 
#Name        : test_atsant.py 
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

""" ats3 custom.py module tests. """

import tempfile
import os

class Bunch(object):
    """ Configuration object. Argument from constructor are converted into class attributes. """
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

def test_atscustom():
    import ats3
    import ats3.custom
    output = os.path.join(tempfile.mkdtemp(), 'ATS3Drop.zip')
    opts = Bunch(file_store='', flash_images='', diamonds_build_url='', testrun_name='', device_type='', report_email='', test_timeout='', drop_file=output, config_file='')
    config = ats3.Configuration(opts, [])
    ats3.custom.create_drop(config)
    assert os.path.exists(output)
