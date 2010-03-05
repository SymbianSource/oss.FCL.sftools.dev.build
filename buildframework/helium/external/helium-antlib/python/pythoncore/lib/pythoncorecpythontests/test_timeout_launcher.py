#============================================================================ 
#Name        : test_timeout_launcher.py 
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
""" unit tests the timeout launcher """

# pylint: disable-msg=E1101

import logging
import sys
import mocker
import subprocess


_logger = logging.getLogger('test.configuration')
logging.basicConfig(level=logging.INFO)

# Platform
WINDOWS = False
if sys.platform == "win32":
    import win32process
    import win32con
    import win32api
    WINDOWS = True



class os(object):
    """ dummy the os function call"""
    def kill(self, pid, value):
        """dummy OS class"""
        pid = value #just for pylint
        return 1

class TimeoutLauncherTest(mocker.MockerTestCase):
    """class containing methods to test the timeout launcher"""

    def test_cmdlineIsEmpty(self):
        """test_cmdlineIsEmpty: nothing in the command line"""
        import timeout_launcher
        obj = self.mocker.replace(timeout_launcher.sys)
        obj.exit(-1)
        self.mocker.result(1)
        self.mocker.replay()
        
        sys.argv = ['timeout_launcher.py', '--timeout=1', 'version']
        timeout_launcher.main()

    def test_valid_with_timeout(self):
        """test_valid_with_timeout: initial test with valid values and timeout."""
        import timeout_launcher
        cmdline =  ['dir']
        shell = True
        if WINDOWS:
            shell = False
        process = self.mocker.mock()
        process.poll()
        self.mocker.result(None)
        process.poll()
        self.mocker.result(1)

        obj = self.mocker.replace("subprocess.Popen")
        obj(' '.join(cmdline), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=shell)
        self.mocker.result(process)

        obj2 = self.mocker.replace(timeout_launcher.sys)
        obj2.exit(mocker.ANY)
        self.mocker.result(1)

        process.communicate()[0]
        self.mocker.result(None)
        process.returncode
        self.mocker.result(1)

        self.mocker.replay()
        
        sys.argv = ['--timeout=1', '--', ' '.join(cmdline)]
        timeout_launcher.main()

    def test_valid_no_timeout(self):
        """test_valid_no_timeout: initial test with valid values and no timeout."""
        import timeout_launcher
        cmdline =  ['dir']
        process = self.mocker.mock()

        obj = self.mocker.replace("subprocess.Popen")
        obj(' '.join(cmdline), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
        self.mocker.result(process)

        process.communicate()[0]
        self.mocker.result(None)
        process.returncode
        self.mocker.result(1)

        obj2 = self.mocker.replace(timeout_launcher.sys)
        obj2.exit(mocker.ANY)
        self.mocker.result(1)
        self.mocker.replay()

        sys.argv = ['--', ' '.join(cmdline)]
        timeout_launcher.main()

    def test_timedout(self):
        """test_timedout: initial test with valid values but times out."""
        import timeout_launcher
        cmdline =  ['dir']
        shell = True
        if WINDOWS:
            shell = False
        process = self.mocker.mock()

        timeValue = self.mocker.replace("time.time")
        timeValue()
        self.mocker.result(1)
        #if debug not set then it won't call the logger functions and so these are not needed
        if logging.DEBUG:
            timeValue()
            self.mocker.result(1)
            timeValue()
            self.mocker.result(1)
            timeValue()
            self.mocker.result(1)
            timeValue()
            self.mocker.result(1)

        obj = self.mocker.replace("subprocess.Popen")
        obj(' '.join(cmdline), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=shell)
        self.mocker.result(process)

        self.mocker.order()
        process.poll()
        self.mocker.result(None)
        timeValue()
        self.mocker.result(5)
        self.mocker.unorder()

        process.pid
        self.mocker.result(0x0129B460)

        if WINDOWS:
            handle = self.mocker.mock()
            handle_1 = self.mocker.replace("win32api.OpenProcess")
            handle_1(True, win32con.PROCESS_TERMINATE, mocker.ANY)
            self.mocker.result(handle)
            handle_1 = self.mocker.replace("win32process.TerminateProcess")
            handle_1(handle, -1)
            

        self.mocker.replay()

        sys.argv = ['--timeout=3', '--', ' '.join(cmdline)]
        failed = False
        try:
            timeout_launcher.main()
        except:
            failed = True
        assert failed

