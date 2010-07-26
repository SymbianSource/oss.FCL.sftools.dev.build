Function-Like Makefiles
------------------------

Tests may be run from the "test" subdirectory.  Simply change into it and type 'make'.

CHECKING YOUR BUILD ENVIRONMENT
--------------------------------
In the test directory type "make envcheck" to see if you have correct path
settings and determine if critical tools are available.

FLMS
----

e32abiv2.flm    # PARENT FLM for building ARMv5 ABIv2 binaries
e32abiv2.mk     # defaults makefile for building ARMv5 ABIv2 binaries 
e32abiv2exe.flm # derived FLM (from e32abiv2.flm) for building ARMv5 ABIv2 exes
e32abiv2dll.flm # derived FLM (from e32abiv2.flm) for building ARMv5 ABIv2 dlls
example_exedll.flm # example flm
extend_exe.flm  # example flm
flmtools.mk     # utility functions for use in flms
grouping.flm    # FLM for creating components
metaflm.mk      # FLM for manipulating and working with other FLMS
readme.txt	# This file
rvct_armv5.mk   # defaults for ARMv5 ABIv2 parameters, used by e32abiv2.mk
standard.xml	# interface file for e32abiv2.flm
test		# ===== Base directory for all tests =====
	Makefile # Glue makefile.  calls grouping.flm to bind all tests
		 # together into a top-level target
	basiclibs
	dllabiv2_1
	dllabiv2_defaults.mk
	exeabiv2_1	# Test building a basic EXE
	exeabiv2_2
	exeabiv2_3
	exeabiv2_defaults.mk
tools			# ======= FLM related tools =======
	command_diff.py # compare two commandlines to find what options are
different
	flm2if.py	# Produce an interface file from an FLM
	flmcheck.py	# Check FLM for errors
	flm.py		# Parse and manipulate flms
	test_command_diff.sh
