#============================================================================ 
#Name        : test_threadpool.py 
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

""" Test cases for threadpool module.

"""

import logging
import sys
import time
import unittest

import threadpool

# Uncomment this line to enable logging in this module, or configure logging elsewhere
logging.basicConfig(level=logging.DEBUG)
_logger = logging.getLogger('test.threadpool')

class Job:
    """Job: a job created, used to test threadpool"""
    def __init__(self, jid):
        self.__id = jid
        
    def __call__(self):
        _logger.debug("Job %d" % self.__id)
        self.work()
        _logger.debug("Job %d - done" % self.__id)
        
    def work(self):
        time.sleep(1)

class LeavingJob(Job):
    """LeavingJob: sleeps and raises exception"""
    def work(self):
        time.sleep(1)
        raise Exception("Error!")
    

class TestThreadPool(unittest.TestCase):
    """TestThreadPool: sets up 6 jobs and clears them down again."""
    def test_thread_pool(self):
        """ Test the thread pool.
        """
        pool = threadpool.ThreadPool(4)
        pool.addWork(Job(1))
        pool.addWork(Job(2))
        pool.addWork(Job(3))
        pool.addWork(Job(4))
        pool.addWork(Job(5))
        pool.addWork(Job(6))
        pool.wait()

    def test_thread_pool_leaving(self):
        """ Test the thread pool when exception happens.
        """
        exceptions = []
        def handle_exception(request, exc_info):
            _logger.debug( "Exception occured in request #%s: %s" % (request.requestID, exc_info[1]))
            exceptions.append(exc_info[1])                        
        pool = threadpool.ThreadPool(4)
        pool.addWork(LeavingJob(1), exc_callback=handle_exception)
        pool.addWork(LeavingJob(2), exc_callback=handle_exception)
        pool.addWork(LeavingJob(3), exc_callback=handle_exception)
        pool.addWork(LeavingJob(4), exc_callback=handle_exception)
        pool.addWork(LeavingJob(5), exc_callback=handle_exception)
        pool.addWork(LeavingJob(6), exc_callback=handle_exception)
        pool.wait()
        assert len(exceptions)==6
        _logger.debug(exceptions)
