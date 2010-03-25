#============================================================================ 
#Name        : test_ccm.py 
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

""" Test cases for ccm python toolkit.

"""

# pylint: disable-msg=E1101

import logging
import os
import sys
import mocker
import ccm


_logger = logging.getLogger('test.ccm')


class CcmTest(mocker.MockerTestCase):
    """ Tests the ccm module using mocker to prevent accessing a real Synergy database. """

    def test_running_sessions(self):
        """ Running sessions can be checked. """
        obj = self.mocker.replace(ccm._execute)
        if sys.platform == "win32":
            obj('c:\\apps\\ccm65\\bin\\ccm.exe status')
        else:
            site_id = 'fa_nmp'
            if 'SITE_ID' in os.environ:
                site_id = os.environ['SITE_ID']
            obj('/nokia/' + site_id + '/apps/cmsynergy/6.5/bin/ccm status')
        self.mocker.result(("""Sessions for user pmackay:

Command Interface @ 1CAL01176:1553:10.241.72.23
Database: /nokia/vc_nmp/groups/gscm/dbs/vc1s60p1

Current project could not be identified.
""", 0))

        self.mocker.replay()

        sessions = ccm.running_sessions()
        print sessions

#    def test_open_session(self):
#        """ ccm session can be opened. """
#        gscm_obj = self.mocker.replace(nokia.gscm._execute)
#        gscm_obj('perl f:\\helium\\svn\\trunk\\helium\\tools/common/bin/get_gscm_info.pl get_router_address /nokia/vc_nmp/groups/gscm/dbs/vc1s60p1')
#        self.mocker.result(("vccmsr65:55414:172.18.95.98:172.18.95.61:172.18.95.95:172.18.95.96:172.18.95.97", 0))
#        
#        obj = self.mocker.replace(ccm._execute)
#        obj('c:\\apps\\ccm65\\bin\\ccm.exe start -m -q -nogui -n username -pw foobar -h vccmsweh.americas.company.com -d /nokia/vc_nmp/groups/gscm/dbs/vc1s60p1')
#        self.mocker.result(("1CAL01176:1333:10.186.216.77:10.241.72.68", 0))
#        
#        self.mocker.replay()
#        session = nokia.nokiaccm.open_session(password='foobar', engine='vccmsweh.americas.company.com', dbpath='/nokia/vc_nmp/groups/gscm/dbs/vc1s60p1', database='/nokia/vc_nmp/groups/gscm/dbs/vc1s60p1')
        
        
    #def test_timeout_launcher(self):
        #sys.path.append(os.path.join(os.environ['HELIUM_HOME'], 'tools/common/python/scripts'))
        #import timeout_launcher
        #backup = sys.argv
        #sys.argv = ['--', 'echo 1']
        #timeout_launcher.main()
        #sys.argv = backup
        