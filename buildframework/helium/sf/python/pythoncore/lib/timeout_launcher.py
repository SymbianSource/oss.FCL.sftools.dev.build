#============================================================================ 
#Name        : timeout_launcher.py 
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

""" Application launcher supporting timeout. """

import os
import sys
import re
import subprocess
import logging
import time

_logger = logging.getLogger('timeout_launcher')
logging.basicConfig(level=logging.INFO)


# Platform
_windows = False
if sys.platform == "win32":
    import win32process
    import win32con
    import win32api
    _windows = True

def main():
    """main method """
    cmdarg = False
    cmdline = []
    timeout = None
    
    for arg in sys.argv:
        res = re.match("^--timeout=(\d+)$", arg)
        if not cmdarg and res is not None:
            timeout = int(res.group(1))
            _logger.debug("Set timeout to %s" % timeout)
        elif not cmdarg and arg == '--':
            _logger.debug("Parsing command start")
            cmdarg = True
        elif cmdarg:
            _logger.debug("Adding arg: %s" % arg)
            cmdline.append(arg)
    
    if len(cmdline) == 0:
        print "Empty command line."
        print "e.g: timeout_launcher.py --timeout=1 -- cmd /c sleep 10"
        sys.exit(-1)
    else:
        _logger.debug("Start command")
        shell = True
        if _windows:
            shell = False
        if timeout != None:
            finish = time.time() + timeout
            timedout = False
            p_file = subprocess.Popen(' '.join(cmdline), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=shell)
            while (p_file.poll() == None):
                if time.time() > finish:
                    timedout = True
                    break
                time.sleep(1)
            if timedout:
                print "ERROR: Application has timed out (timeout=%s)." % timeout
                if _windows:
                    try:
                        print "ERROR: Trying to kill the process..."
                        handle = win32api.OpenProcess(True, win32con.PROCESS_TERMINATE, p_file.pid)
                        win32process.TerminateProcess(handle, -1)
                        print "ERROR: Process killed..."
                    except Exception, exc:
                        print "ERROR: %s" % exc
                else:
                    os.kill(p_file.pid, 9) # pylint: disable=E1101
                print "ERROR: exiting..."
                raise Exception("Timeout exception.")
            else:
                print p_file.communicate()[0]
                sys.exit(p_file.returncode)
        else:
            p_file = subprocess.Popen(' '.join(cmdline), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=shell)
            print p_file.communicate()[0]
            sys.exit(p_file.returncode)

if __name__ == '__main__':
    main()