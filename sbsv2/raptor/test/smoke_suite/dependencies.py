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
import os

def run():
	t = AntiTargetSmokeTest()
	t.usebash = True
	
	genericTargets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dependency.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/dependency.exe.map",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dependency.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/dependency.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/urel/dependency.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/dependency.exe.map",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/dependency.exe",
		"$(EPOCROOT)/epoc32/include/dependency.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/dependency.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/dependency.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/dependency.rsc",
		"$(EPOCROOT)/epoc32/include/main.rsg",
		"$(EPOCROOT)/epoc32/data/z/resource/apps/main.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/z/resource/apps/main.rsc",
		"$(EPOCROOT)/epoc32/release/winscw/urel/z/resource/apps/main.rsc"
		]
	windowsTargets = [
		"$(EPOCROOT)/epoc32/release/tools2/rel/dependency.exe",
		"$(EPOCROOT)/epoc32/tools/dependency.exe"
	]
	linuxTargets = [
		"$(EPOCROOT)/epoc32/release/tools2/$(HOSTPLATFORM_DIR)/rel/dependency",
		"$(EPOCROOT)/epoc32/tools/dependency"
	]

	# Set general host platform specifics from first test run, but assume Windows initially
	hostPlatform = "windows"
	hostPlatformTargets = genericTargets + windowsTargets
	hostPlatformOffset = ""

	t.id = "0098a"
	t.name = "baseline_build"
	t.description = "Build a component with source and resource files that are dependent on header files exported in the build"
	t.command = """
		cp smoke_suite/test_resources/dependencies/src/dependency1.cpp smoke_suite/test_resources/dependencies/dependency.cpp
		cp smoke_suite/test_resources/dependencies/src/dependency1.rss smoke_suite/test_resources/dependencies/dependency.rss
		sbs -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel"""		
	t.mustnotmatch = [
		"<warning>Missing dependency detected: .*</warning>"
	]
	t.targets = hostPlatformTargets
	t.run(hostPlatform)
	if t.result == AntiTargetSmokeTest.SKIP:
		hostPlatform = "linux"
		hostPlatformTargets = genericTargets + linuxTargets
		hostPlatformOffset = "$(HOSTPLATFORM_DIR)/"
		t.targets = hostPlatformTargets
		t.run(hostPlatform)
	
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
		[".*recipe name='resourcecompile", 2]
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
	# Note that the resource build does not exhibit a missing dependency as its dependency files are generated in a separate stage where
	# the target file isn't actually a target of that stage
	t.mustmatch.extend([
		"<warning>Missing dependency detected: .*/epoc32/include/dependency.h</warning>"
		])
	t.warnings = 1
	t.run()
	

	t.id = "0098d"
	t.name ="invalid_dependency_files"
	t.description = "Invalidate dependency files, then make sure we can clean and re-build successfully"
	buildLocation = "$(EPOCROOT)/epoc32/build/" + BldInfFile.outputPathFragment('smoke_suite/test_resources/dependencies/bld.inf') + "/dependency_"
        # use one long bash command so that we can capture 
	# the output in a way that isn't messed up with all the ordering confused.
	t.command = " mkdir -p $(EPOCROOT)/epoc32/build/smoketestlogs ; { sleep 1 ; set -x ; \
touch smoke_suite/test_resources/dependencies/dependency.cpp; \
echo INVALIDATE_ARMV5_DEPENDENCY_FILE >> %s/armv5/urel/dependency.o.d ; \
echo INVALIDATE_WINSCW_DEPENDENCY_FILE >> %s/winscw/urel/dependency.o.d ;\
echo INVALIDATE_TOOLS2_DEPENDENCY_FILE >> %s/dependency_exe/tools2/rel/%s/dependency.o.d ;\
echo INVALIDATE_RESOURCE_DEPENDENCY_FILE >> %s/dependency__resource_apps.rsc.d ;\
sbs -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel ;\
sbs -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel clean ;\
sbs -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel ; } > ${SBSLOGFILE} 2>&1; grep 'missing separator' ${SBSLOGFILE} " %(buildLocation, buildLocation, buildLocation, hostPlatformOffset, buildLocation)
	# We expect an error from the first build due to the deliberate dependency file corruption
	t.mustmatch = [
		".*dependency.o.d:[0-9]+: \*\*\* missing separator"
		]
	t.countmatch = []
	t.warnings = 0
	t.errors = 0 
	t.targets = hostPlatformTargets
	t.run(hostPlatform)


	t.id = "0098e"
	t.name ="no_depend_include"
	t.description = "Invalidate dependency files in order to confirm they aren't processed when --no-depend-include is used"
	buildLocation = "$(EPOCROOT)/epoc32/build/" + BldInfFile.outputPathFragment('smoke_suite/test_resources/dependencies/bld.inf') + "/dependency_"
	t.command = """
		sleep 1
		touch smoke_suite/test_resources/dependencies/dependency.cpp
		echo INVALIDATE_ARMV5_DEPENDENCY_FILE >> """+buildLocation+"""/armv5/urel/dependency.o.d
		echo INVALIDATE_WINSCW_DEPENDENCY_FILE >> """+buildLocation+"""/winscw/urel/dependency.o.d
		echo INVALIDATE_TOOLS2_DEPENDENCY_FILE >> """+buildLocation+"""/dependency_exe/tools2/rel/"""+hostPlatformOffset+"""dependency.o.d
		sbs --no-depend-include -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel"""
	t.mustmatch = []
	t.errors = 0		
	t.targets = hostPlatformTargets
	t.run(hostPlatform)


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
		echo INVALIDATE_TOOLS2_DEPENDENCY_FILE >> """+buildLocation+"""/dependency_exe/tools2/rel/"""+hostPlatformOffset+"""dependency.o.d
		sbs --no-depend-generate -b smoke_suite/test_resources/dependencies/bld.inf -c default -c tools2_rel"""
	t.antitargets = [
		buildLocation+"/armv5/urel/main.o.d",
		buildLocation+"/armv5/udeb/main.o.d",
		buildLocation+"/winscw/urel/main.o.d",
		buildLocation+"/winscw/udeb/main.o.d",
		buildLocation+"/dependency_exe/tools2/rel/"+hostPlatformOffset+"main.o.d"
		]
	t.targets = hostPlatformTargets
	t.run(hostPlatform)
	
	# clean-up
	os.remove("smoke_suite/test_resources/dependencies/dependency.cpp")
	os.remove("smoke_suite/test_resources/dependencies/dependency.rss")

	t.id = "98"
	t.name = "dependencies"
	t.print_result()
	return t

