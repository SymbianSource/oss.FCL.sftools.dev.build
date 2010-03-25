#============================================================================ 
#Name    : test_atsconfigparser.py
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

""" Testing the ATS configuration file """

import os
import logging
import tempfile
import unittest

import ats3.atsconfigparser

_logger = logging.getLogger('test.atsconfigparser')
logging.basicConfig(level=logging.INFO)

class AtsConfigParserTest(unittest.TestCase):
    """class used to test ATS config parser"""
    def test_converttestxml(self):
        """setup test data, call the convert to XML method (part being tested) 
        then check it is correct"""
        spectext = """<ATSConfigData>
    <config name="common" abstract="true">

        <!-- Properties to add/modify -->
        <config type="properties">
           <set name="HARNESS" value="STIFx" />
           <set name="HARNESS2" value="STIF2"/>
           <set name="HARNESS3" value="STIF2"/>
           <set name="2" value="3" />
        </config>

        <!-- Attributes to modify -->
        <config type="attributes">
           <set name="xyz" value="2" />
           <set name="significant" value="true" />
        </config>

        <!-- Settings to add/modify -->
        <config type="settings">
           <set name="HARNESS" value="STIF" />
           <set name="2" value="3" />
        </config>

    </config>
</ATSConfigData>
        """

        testxmldata = """<test>
  <name>helium_clock</name>
  <target>
    <device alias="DEFAULT_STIF" rank="none">
      <property name="HARNESS" value="STIF"/>
      <property name="HARNESS2" value="STIF"/>
      <property name="HARNESS3" value="STIF"/>
    </device>
    <device alias="DEFAULT_EUIT" rank="none">
      <property name="HARNESS" value="STIF"/>
      <property name="HARNESS2" value="STIF3"/>
    </device>
  </target>
  <plan passrate="100" harness="STIF" enabled="true" name="helium_clock Plan" significant="false">
    <session passrate="100" harness="STIF" enabled="true" name="session" significant="false">
      <set passrate="100" harness="STIF" enabled="true" name="set0" significant="false">
        <target>
          <device alias="DEFAULT_STIF" rank="master"/>
        </target>
      </set>
    </session>
  </plan>
</test>
        """

        (file_descriptor, filename) = tempfile.mkstemp()
        file_handle = os.fdopen(file_descriptor, 'w')
        file_handle.write(spectext)
        file_handle.close()

        output = ats3.atsconfigparser.converttestxml(filename, testxmldata)
        os.remove(filename)
        _logger.info(output)
        self.assert_( '<property name="2" value="3"/>' in output)
        self.assert_( '<property name="HARNESS" value="STIFx"/>' in output)
        self.assert_( '<property name="HARNESS" value="STIF"/>' not in output)
        self.assert_( '<property name="HARNESS2" value="STIF2"/>' in output)
        self.assert_( '<property name="HARNESS2" value="STIF3"/>' not in output)
        self.assert_( '<property name="HARNESS3" value="STIF2"/>' in output)
