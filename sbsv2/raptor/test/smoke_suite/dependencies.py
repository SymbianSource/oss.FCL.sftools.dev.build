#
# Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

from raptor_tests import AntiTargetSmokeTest
from raptor_meta import BldInfFile

def run():
	t = AntiTargetSmokeTest()
	t.usebash = True
	
	targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dependency.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dependency.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dependency.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dependency.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/dependency.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/dependency.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/dependency.exe",
		"$(EPOCROOT)/epoc32/release/tools2/rel/dependency.exe",
		"$(EPOCROOT)/epoc32/tools/dependency.exe",
		"$(EPOCROOT)/epoc32/include/dependency.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/dependency.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/dependency.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/dependency.rsc",
		"$(EPOCROOT)/epoc32/include/main.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/main.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/main.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/main.rsc"
		]

	t.id = "0098a"
	t.name = "baseline_build"
	t.description = "Build a component with source and resource files that are dependent on header files exported in the build"
	t.command = """
		cp smoke_suite/test_resources/dependencies/src/dependency1.cpp smoke_suite/test_resources/dependencies/dependency.cpp
		cp smoke_suite/test_resources/dependencies/src/dependency1.rss smoke_suite/test_resources/dependencies/dependency.rss
		sbs -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel"""		
	t.targets = targets
	t.mustnotmatch = [
		"<warning>Missing dependency detected: .*</warning>"
	]
	t.run()
	
	# Ensure we don't clean up from the previous build in the following two tests
	t.targets = []
	
	# Core expected outcome for the following two tests
	t.mustmatch = [
		".*recipe name='compile' target='.*dependency\.o'",
		".*recipe name='win32compile2object' target='.*dependency\.o'",
		".*recipe name='compile2object' target='.*dependency\.o'",
		".*recipe name='resourcecompile' target='.*dependency\.rsc'"
	]
	t.countmatch = [
		[".*recipe name='compile'", 2],
		[".*recipe name='win32compile2object'", 2],
		[".*recipe name='compile2object'", 1],
		[".*recipe name='resourcecompile'", 1]
	]
	
	t.id = "0098b"
	t.name ="touched_header_dependencies"
	t.description = "Touch the exported header files and check that only the related source and resource files are re-built"
	t.command = """
		sleep 1
		touch $(EPOCROOT)/epoc32/include/dependency.h
		touch $(EPOCROOT)/epoc32/include/dependency.rh
		sbs -f- -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel"""
	t.run()
	
	t.id = "0098c"
	t.name ="redundant_header_dependencies"
	t.description = """
		Build the component again, but manipulate it so that (a) it no longer has a dependency on the exported header files and
		(b) the header files have been removed and (c) the header files are no longer exported.  Check that only the related source
		and resource files are re-built"""
	t.command = """
		cp smoke_suite/test_resources/dependencies/src/dependency2.cpp smoke_suite/test_resources/dependencies/dependency.cpp
		cp smoke_suite/test_resources/dependencies/src/dependency2.rss smoke_suite/test_resources/dependencies/dependency.rss
		rm -rf $(EPOCROOT)/epoc32/include/dependency.h
		rm -rf $(EPOCROOT)/epoc32/include/dependency.rh
		sbs -f- --noexport -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel"""
	t.mustnotmatch = []
	t.mustmatch.extend([
		"<warning>Missing dependency detected: $(EPOCROOT)/epoc32/include/dependency.h</warning>",
		"<warning>Missing dependency detected: $(EPOCROOT)/epoc32/include/dependency.rh</warning>",		
		])
	t.run()
	
	t.id = "0098d"
	t.name ="invalid_dependency_files"
	t.description = "Invalidate dependency files, then make sure we can clean and re-build successfully"
	buildLocation = "$(EPOCROOT)/epoc32/build/" + BldInfFile.outputPathFragment('smoke_suite/test_resources/dependencies/bld.inf') + "/dependency_"
	t.command = """
		sleep 1
		touch smoke_suite/test_resources/dependencies/dependency.cpp
		echo INVALIDATE_ARMV5_DEPENDENCY_FILE >> """+buildLocation+"""/armv5/urel/dependency.o.d
		echo INVALIDATE_WINSCW_DEPENDENCY_FILE >> """+buildLocation+"""/winscw/urel/dependency.o.d
		echo INVALIDATE_TOOLS2_DEPENDENCY_FILE >> """+buildLocation+"""/dependency_exe/tools2/rel/dependency.o.d
		echo INVALIDATE_RESOURCE_DEPENDENCY_FILE >> """+buildLocation+"""/dependency__resource_apps_sc.rpp.d
		sbs -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel
		sbs -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel clean
		sbs -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel"""		
	t.targets = targets
	t.mustmatch = []
	t.countmatch = []
	t.errors = 1 # We expect an error from the first build due to the deliberate dependency file corruption
	t.run()

	t.errors = 0

	t.id = "0098e"
	t.name ="no_depend_include"
	t.description = "Invalidate dependency files in order to confirm they aren't processed when --no-depend-include is used"
	buildLocation = "$(EPOCROOT)/epoc32/build/" + BldInfFile.outputPathFragment('smoke_suite/test_resources/dependencies/bld.inf') + "/dependency_"
	t.command = """
		sleep 1
		touch smoke_suite/test_resources/dependencies/dependency.cpp
		echo INVALIDATE_ARMV5_DEPENDENCY_FILE >> """+buildLocation+"""/armv5/urel/dependency.o.d
		echo INVALIDATE_WINSCW_DEPENDENCY_FILE >> """+buildLocation+"""/winscw/urel/dependency.o.d
		echo INVALIDATE_TOOLS2_DEPENDENCY_FILE >> """+buildLocation+"""/dependency_exe/tools2/rel/dependency.o.d
		sbs --no-depend-include -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel"""		
	t.targets = targets
	t.run()

	t.id = "0098f"
	t.name ="no_depend_generate"
	t.description = "Invalidate and remove dependency files in order to confirm they are neither included nor re-generated when --no-depend-generate is used"
	buildLocation = "$(EPOCROOT)/epoc32/build/" + BldInfFile.outputPathFragment('smoke_suite/test_resources/dependencies/bld.inf') + "/dependency_"
	t.command = """
		sleep 1
		touch smoke_suite/test_resources/dependencies/dependency.cpp
		touch smoke_suite/test_resources/dependencies/main.cpp
		echo INVALIDATE_ARMV5_DEPENDENCY_FILE >> """+buildLocation+"""/armv5/urel/dependency.o.d
		echo INVALIDATE_WINSCW_DEPENDENCY_FILE >> """+buildLocation+"""/winscw/urel/dependency.o.d
		echo INVALIDATE_TOOLS2_DEPENDENCY_FILE >> """+buildLocation+"""/dependency_exe/tools2/rel/dependency.o.d
		sbs --no-depend-generate -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel"""		
	t.targets = targets
	t.antitargets = [
		buildLocation+"/armv5/urel/main.o.d",
		buildLocation+"/armv5/udeb/main.o.d",
		buildLocation+"/winscw/urel/main.o.d",
		buildLocation+"/winscw/udeb/main.o.d",
		buildLocation+"/dependency_exe/tools2/rel/main.o.d"
		]
	t.run()

	t.id = "98"
	t.name = "dependencies"
	t.print_result()
	return t
