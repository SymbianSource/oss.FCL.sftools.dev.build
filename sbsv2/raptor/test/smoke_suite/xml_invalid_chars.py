#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description: 
#

from raptor_tests import SmokeTest, ReplaceEnvs
from xml.etree.ElementTree import parse

def run():
	t = SmokeTest()
	t.id = "84"
	t.name = "xml_invalid_chars"
	t.description = """Tests the validity of XML when output with characters
			not-allowed in XML are sent to the filters
			"""
	t.command = "sbs -b smoke_suite/test_resources/xml_invalid_chars/bld.inf " \
			+ "-c armv5"
	# The warning that causes the invalid characters to appear in the XML log
	t.warnings = 1
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/urel/test.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/test.exe"
		]
	t.addbuildtargets('smoke_suite/test_resources/xml_invalid_chars/bld.inf', [
		"test_/armv5/urel/test_urel_objects.via",
		"test_/armv5/urel/test.o.d",
		"test_/armv5/urel/test.o",
		"test_/armv5/udeb/test_udeb_objects.via",
		"test_/armv5/udeb/test.o.d",
		"test_/armv5/udeb/test.o"
	])
		
	t.run()
	
	if t.result == SmokeTest.PASS:
		
		print "Testing validity of XML..."
		
		log = "$(EPOCROOT)/epoc32/build/smoketestlogs/xml_invalid_chars.log"
		logfile = open(ReplaceEnvs(log), "r")
		
		try:
			tree = parse(logfile)
		except:
			t.result = SmokeTest.FAIL
	
	t.print_result()
	return t
