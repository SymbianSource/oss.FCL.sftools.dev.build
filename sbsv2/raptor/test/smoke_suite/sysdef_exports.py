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

from raptor_tests import SmokeTest

def run():
	t = SmokeTest()
	t.id = "47"
	t.name = "sysdef_exports"
	t.description = "Test general system_definition.xml processing of exports"
	t.command = "sbs -a $(SBS_HOME)/test/smoke_suite/test_resources/sysdef -s smoke_suite/test_resources/sysdef/system_definition_mmp_export_dependencies_test.xml"
	t.targets = [
		"$(SBS_HOME)/test/smoke_suite/test_resources/sysdef/dependent_on_exports/metadata_export_pre1.mmh",
		"$(SBS_HOME)/test/smoke_suite/test_resources/sysdef/dependent_on_exports/metadata_export_pre2.mmh",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dependent_on_exports.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dependent_on_exports.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dependent_on_exports.exe.sym",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dependent_on_exports.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dependent_on_exports.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dependent_on_exports.exe.sym",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/dependent_on_exports.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/dependent_on_exports.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/dependent_on_exports.exe.map"
		]
	t.addbuildtargets('smoke_suite/test_resources/sysdef/dependent_on_exports/bld.inf', [
		"dependent_on_exports_exe/armv5/udeb/dependent_on_exports_udeb_objects.via",
		"dependent_on_exports_exe/armv5/udeb/test.o",
		"dependent_on_exports_exe/armv5/udeb/test.o.d",
		"dependent_on_exports_exe/armv5/urel/dependent_on_exports_urel_objects.via",
		"dependent_on_exports_exe/armv5/urel/test.o",
		"dependent_on_exports_exe/armv5/urel/test.o.d",
		"dependent_on_exports_exe/winscw/udeb/dependent_on_exports.UID.CPP",
		"dependent_on_exports_exe/winscw/udeb/dependent_on_exports_UID_.dep",
		"dependent_on_exports_exe/winscw/udeb/dependent_on_exports_UID_.o",
		"dependent_on_exports_exe/winscw/udeb/test.dep",
		"dependent_on_exports_exe/winscw/udeb/test.o",
		"dependent_on_exports_exe/winscw/urel/dependent_on_exports.UID.CPP",
		"dependent_on_exports_exe/winscw/urel/dependent_on_exports_UID_.dep",
		"dependent_on_exports_exe/winscw/urel/dependent_on_exports_UID_.o",
		"dependent_on_exports_exe/winscw/urel/test.dep",
		"dependent_on_exports_exe/winscw/urel/test.o"
	])
	t.run()
	return t
