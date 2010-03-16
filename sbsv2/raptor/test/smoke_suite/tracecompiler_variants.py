#
# Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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
from raptor_tests import AntiTargetSmokeTest

def run():
	# 102a - 102b Test running trace compiler on one mmp with different source files controlled macros. 
	t = AntiTargetSmokeTest()
	t.description = "Testcases (ID 102a - 102c) test trace compiler running with variants and macros"
	
	# 1st time build includes var_source1 and var_source2 for variant_source.mmp
	t.id = "102a"
	t.name = "TC_variant_source_var1"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/variant_source/group/bld.inf -c default.tc_var1" + \
			" --configpath=test/smoke_suite/test_resources/tracecompiler/variant_source"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/invariant_source.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/variant_source.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/invariant_source.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/variant_source.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/invariant_source.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/variant_source.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/invariant_source.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/variant_source.exe",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/variant_source/traces/inv_sourceTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/variant_source/traces/var_source1Traces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/variant_source/traces/var_source2Traces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/variant_source/traces/fixed_id.definitions",
		"$(EPOCROOT)/epoc32/ost_dictionaries/invariant_source_0x10000002_Dictionary.xml",
		"$(EPOCROOT)/epoc32/ost_dictionaries/variant_source_0x10000003_Dictionary.xml",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/invariant_source_0x10000002_TraceDefinitions.h",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/variant_source_0x10000003_TraceDefinitions.h"
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/variant_source/group/bld.inf', [
		"invariant_source_/armv5/udeb/inv_source.o",
		"invariant_source_/armv5/udeb/inv_source.o.d",
		"invariant_source_/armv5/urel/inv_source.o",
		"invariant_source_/armv5/urel/inv_source.o.d",
		"invariant_source_/winscw/udeb/inv_source.o",
		"invariant_source_/winscw/udeb/inv_source.o.d",
		"invariant_source_/winscw/urel/inv_source.o",
		"invariant_source_/winscw/urel/inv_source.o.d",
		"invariant_source_/tracecompile_invariant_source_10000002.done",
		"variant_source_/armv5/udeb/var_source1.o",
		"variant_source_/armv5/udeb/var_source1.o.d",
		"variant_source_/armv5/udeb/var_source2.o",
		"variant_source_/armv5/udeb/var_source2.o.d",
		"variant_source_/armv5/urel/var_source1.o",
		"variant_source_/armv5/urel/var_source1.o.d",
		"variant_source_/armv5/urel/var_source2.o",
		"variant_source_/armv5/urel/var_source2.o.d",
		"variant_source_/winscw/udeb/var_source1.o",
		"variant_source_/winscw/udeb/var_source1.o.d",
		"variant_source_/winscw/udeb/var_source2.o",
		"variant_source_/winscw/udeb/var_source2.o.d",
		"variant_source_/winscw/urel/var_source1.o",
		"variant_source_/winscw/urel/var_source1.o.d",
		"variant_source_/winscw/urel/var_source2.o",
		"variant_source_/winscw/urel/var_source2.o.d",
		"variant_source_/tracecompile_variant_source_10000003.done"
	])
	t.antitargets = [
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/variant_source/traces/var_source3Traces.h"
		]
	t.addbuildantitargets('smoke_suite/test_resources/tracecompiler/variant_source/group/bld.inf', [
		"variant_source_/armv5/udeb/var_source3.o",
		"variant_source_/armv5/urel/var_source3.o",
		"variant_source_/winscw/udeb/var_source3.o",
		"variant_source_/winscw/urel/var_source3.o"
	])
	t.run()

	# 2nd time build includes var_source1 and var_source3 for variant_source.mmp
	t = SmokeTest()
	t.id = "102b"
	t.name = "TC_variant_source_var2"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/variant_source/group/bld.inf -c default.tc_var2" + \
			" --configpath=test/smoke_suite/test_resources/tracecompiler/variant_source"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/invariant_source.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/variant_source.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/invariant_source.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/variant_source.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/invariant_source.exe",
		"$(EPOCROOT)/epoc32/release/winscw/udeb/variant_source.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/invariant_source.exe",
		"$(EPOCROOT)/epoc32/release/winscw/urel/variant_source.exe",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/variant_source/traces/inv_sourceTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/variant_source/traces/var_source1Traces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/variant_source/traces/var_source2Traces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/variant_source/traces/var_source3Traces.h",
		"$(EPOCROOT)/epoc32/ost_dictionaries/invariant_source_0x10000002_Dictionary.xml",
		"$(EPOCROOT)/epoc32/ost_dictionaries/variant_source_0x10000003_Dictionary.xml",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/invariant_source_0x10000002_TraceDefinitions.h",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/variant_source_0x10000003_TraceDefinitions.h"
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/variant_source/group/bld.inf', [
		"invariant_source_/armv5/udeb/inv_source.o",
		"invariant_source_/armv5/udeb/inv_source.o.d",
		"invariant_source_/armv5/urel/inv_source.o",
		"invariant_source_/armv5/urel/inv_source.o.d",
		"invariant_source_/winscw/udeb/inv_source.o",
		"invariant_source_/winscw/udeb/inv_source.o.d",
		"invariant_source_/winscw/urel/inv_source.o",
		"invariant_source_/winscw/urel/inv_source.o.d",
		"invariant_source_/tracecompile_invariant_source_10000002.done",
		"variant_source_/armv5/udeb/var_source1.o",
		"variant_source_/armv5/udeb/var_source1.o.d",
		"variant_source_/armv5/udeb/var_source3.o",
		"variant_source_/armv5/udeb/var_source3.o.d",
		"variant_source_/armv5/urel/var_source1.o",
		"variant_source_/armv5/urel/var_source1.o.d",
		"variant_source_/armv5/urel/var_source3.o",
		"variant_source_/armv5/urel/var_source3.o.d",
		"variant_source_/winscw/udeb/var_source1.o",
		"variant_source_/winscw/udeb/var_source1.o.d",
		"variant_source_/winscw/udeb/var_source3.o",
		"variant_source_/winscw/udeb/var_source3.o.d",
		"variant_source_/winscw/urel/var_source1.o",
		"variant_source_/winscw/urel/var_source1.o.d",
		"variant_source_/winscw/urel/var_source3.o",
		"variant_source_/winscw/urel/var_source3.o.d",
		"variant_source_/tracecompile_variant_source_10000003.done"
	])
	t.run()

	# Build multiple variants together, which involves different source files in one mmp
	# Raptor only call trace compiler once no matter how many variants
	# In this example, ".phone" 1 2 3 involve tc_a b c respectively, and all involve tc_main
	t = SmokeTest()
	t.id = "102c"
	t.name = "TC_multiple_variants"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/multiple_variants/group/bld.inf" + \
			" -c armv5.phone1 -c armv5.phone2 -c armv5.phone3" + \
			" --configpath=test/smoke_suite/test_resources/tracecompiler/multiple_variants"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5.phone1/udeb/tc_variants.exe",
		"$(EPOCROOT)/epoc32/release/armv5.phone1/urel/tc_variants.exe",
		"$(EPOCROOT)/epoc32/release/armv5.phone2/udeb/tc_variants.exe",
		"$(EPOCROOT)/epoc32/release/armv5.phone2/urel/tc_variants.exe",
		"$(EPOCROOT)/epoc32/release/armv5.phone3/udeb/tc_variants.exe",
		"$(EPOCROOT)/epoc32/release/armv5.phone3/urel/tc_variants.exe",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/multiple_variants/traces/tc_mainTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/multiple_variants/traces/tc_aTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/multiple_variants/traces/tc_bTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/multiple_variants/traces/tc_cTraces.h",
		"$(EPOCROOT)/epoc32/ost_dictionaries/tc_variants_0x10000004_Dictionary.xml",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/tc_variants_0x10000004_TraceDefinitions.h"
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/multiple_variants/group/bld.inf', [
		"tc_variants_/armv5.phone1/udeb/tc_main.o",
		"tc_variants_/armv5.phone1/udeb/tc_a.o",
		"tc_variants_/armv5.phone1/urel/tc_main.o",
		"tc_variants_/armv5.phone1/urel/tc_a.o",
		"tc_variants_/armv5.phone2/udeb/tc_main.o",
		"tc_variants_/armv5.phone2/udeb/tc_b.o",
		"tc_variants_/armv5.phone2/urel/tc_main.o",
		"tc_variants_/armv5.phone2/urel/tc_b.o",
		"tc_variants_/armv5.phone3/udeb/tc_main.o",
		"tc_variants_/armv5.phone3/udeb/tc_c.o",
		"tc_variants_/armv5.phone3/urel/tc_main.o",
		"tc_variants_/armv5.phone3/urel/tc_c.o",
		"tc_variants_/tracecompile_tc_variants_10000004.done"
	])	
	t.run()

	# 102d and 102e is to test a very rare situation, where one mmpfile includes 3 children mmpfiles, 
	# which are guarded by macros. They share some source file, and two share the same UID3. 
	# When build them together, Raptor should be able to distinguish them and run trace compiler 
	# on each of them. 
	t = SmokeTest()
	t.id = "102d"
	t.name = "TC_mum_children_mmps_build"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/mum_children_mmps/group/bld.inf" + \
			" -c armv5.tc_var1 -c armv5.tc_var2 -c armv5.tc_var3" + \
			" --configpath=test/smoke_suite/test_resources/tracecompiler/mum_children_mmps"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/child1.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/child1.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/child2.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/child2.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/child3.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/child3.exe",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child1_exe/child1Traces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child1_exe/commonTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child2_exe/child2Traces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child2_exe/commonTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child3_exe/child3Traces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child3_exe/commonTraces.h",
		"$(EPOCROOT)/epoc32/ost_dictionaries/child1_exe_0x11100001_Dictionary.xml",
		"$(EPOCROOT)/epoc32/ost_dictionaries/child2_exe_0x11100002_Dictionary.xml",
		"$(EPOCROOT)/epoc32/ost_dictionaries/child3_exe_0x11100002_Dictionary.xml",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/child1_exe_0x11100001_TraceDefinitions.h",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/child2_exe_0x11100002_TraceDefinitions.h",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/child3_exe_0x11100002_TraceDefinitions.h"
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/mum_children_mmps/group/bld.inf', [
		"child1_/armv5/udeb/child1.o",
		"child1_/armv5/udeb/common.o",
		"child1_/armv5/urel/child1.o",
		"child1_/armv5/urel/common.o",
		"child1_/tracecompile_child1_exe_11100001.done",
		"child2_/armv5/udeb/child2.o",
		"child2_/armv5/udeb/common.o",
		"child2_/armv5/urel/child2.o",
		"child2_/armv5/urel/common.o",
		"child2_/tracecompile_child2_exe_11100002.done",
		"child3_/armv5/udeb/child3.o",
		"child3_/armv5/udeb/common.o",
		"child3_/armv5/urel/child3.o",
		"child3_/armv5/urel/common.o",
		"child3_/tracecompile_child3_exe_11100002.done"
	])
	t.warnings = 3
	t.run()

	# Clean mmp A then build mmp B and C. As common.cpp is shared by A B and C, commonTraces.h would be 
	# cleaned when cleaning mmp A. But as B and C aren't cleaned, Raptor wouldn't run trace compiler on
	# B and C, thus commonTraces.h wouldn't be generated again, so be missing for mmp B and C.
	# The solution is to use new trace path "traces_<TARGET>_<TARGETTYPE>" instead of "traces" so shared 
	# source has different copy of trace headers for different projects.
	t = SmokeTest()
	t.id = "102e"
	t.name = "TC_mum_children_mmps_clean"
	t.command = "sbs -b smoke_suite/test_resources/tracecompiler/mum_children_mmps/group/bld.inf" + \
			" --configpath=test/smoke_suite/test_resources/tracecompiler/mum_children_mmps" + \
			" -c armv5.tc_var1 CLEAN && " + \
			"sbs -b smoke_suite/test_resources/tracecompiler/mum_children_mmps/group/bld.inf" + \
			" --configpath=test/smoke_suite/test_resources/tracecompiler/mum_children_mmps" + \
			" -c armv5.tc_var2 -c armv5.tc_var3"
	t.targets = [
		"$(EPOCROOT)/epoc32/release/armv5/udeb/child2.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/child2.exe",
		"$(EPOCROOT)/epoc32/release/armv5/udeb/child3.exe",
		"$(EPOCROOT)/epoc32/release/armv5/urel/child3.exe",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child2_exe/child2Traces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child2_exe/commonTraces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child3_exe/child3Traces.h",
		"$(SBS_HOME)/test/smoke_suite/test_resources/tracecompiler/mum_children_mmps/traces_child3_exe/commonTraces.h",
		"$(EPOCROOT)/epoc32/ost_dictionaries/child2_exe_0x11100002_Dictionary.xml",
		"$(EPOCROOT)/epoc32/ost_dictionaries/child3_exe_0x11100002_Dictionary.xml",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/child2_exe_0x11100002_TraceDefinitions.h",
		"$(EPOCROOT)/epoc32/include/internal/symbiantraces/autogen/child3_exe_0x11100002_TraceDefinitions.h"
		]
	t.addbuildtargets('smoke_suite/test_resources/tracecompiler/mum_children_mmps/group/bld.inf', [
		"child2_/armv5/udeb/child2.o",
		"child2_/armv5/udeb/common.o",
		"child2_/armv5/urel/child2.o",
		"child2_/armv5/urel/common.o",
		"child2_/tracecompile_child2_exe_11100002.done",
		"child3_/armv5/udeb/child3.o",
		"child3_/armv5/udeb/common.o",
		"child3_/armv5/urel/child3.o",
		"child3_/armv5/urel/common.o",
		"child3_/tracecompile_child3_exe_11100002.done"
	])
	t.warnings = 3
	t.run()


	t.id = "102"
	t.name = "tracecompiler_variants"
	t.print_result()
	
	return t

