##
# Create and check test environment.
# build all tests.

## Purpose: Run test makefiles in parallel to ensure that they all work
## Postconditions: All postconditions for all the makefiles are satisfied

# Parameters which may be overridden by the environment:
RAPTOR_HOME?=/localhome/tmurphy/pf/EPOC/development/tools/personal/tmurphy/tools/raptor
# Need elf2e32 etc.
RAPTOOLS?=/localhome/tmurphy/raptools/linux86
EPOCROOT?=/tmp/tim-epocroot
# End of Environment-overridable parameters.

#Where are flms located?
FLMHOME:=$(RAPTOR_HOME)/lib/flm
FLMTESTHOME:=$(FLMHOME)/test
SOURCEPATH:=$(FLMHOME)/test


.PHONY:: all

#### Call all the test makefiles ##############
ALLTARGET:=all

OUTPUTPATH=$(EPOCROOT)/epoc32/build
RELEASEPATH:=$(EPOCROOT)/epoc32/release
FULLVARIANTPATH:=ARMV5/UREL

include $(FLMHOME)/test/exebasictests.mk

include $(FLMHOME)/test/ciatests.mk

include $(FLMHOME)/test/exeperftests.mk

include $(FLMHOME)/test/dllbasictests.mk

###############################################

#EPOCROOT:=
SYSTEMSOURCEPATH:=/c/p4_Perforce011666_LON-TIMOTHYM01/EPOC/development/tools/personal/tmurphy/EPOC/master
OSNAME:=cedar
#include $(FLMHOME)/system.flm

flmcheck:: flmtoolscheck
	@ERRCOUNT=0; for i in $(FLMHOME)/*.flm; do \
		$(FLMHOME)/tools/flmcheck.py  $$i; ERRCOUNT=$$[ $$ERRCOUNT + $$?];  done;  \
		echo "flmcheck issued warnings for $$ERRCOUNT  FLMS.";
		@true # For the time being this is not a sufficient condition to stop the tests

# Run through the flmtools tests to make sure thye work
flmtoolscheck::
	make -f ../flmtools.mk STANDALONE_TEST:=1 FLMHOME:=$(FLMHOME) test

envcheck::
	@echo "<envcheck>"
	@echo -n "<elf2e32>"; ELF2E32=`which elf2e32`; if [ "$$ELF2E32" == "" ]; then echo -n "elf2e32 not available in the path."; else echo -n "$$ELF2E32"; fi; echo "<elf2e32>"
	@echo -n "<make>"; make -v | egrep '^.*GNU Make 3.81.*$$' ; if [ $$? -ne 0 ]; then echo -n "Version of make in the path appears not to be 3.81."; fi; echo "<make>"
	@echo -n "<tranasm>"; $$TRANASM | egrep 'tranasm' ; if [ $$? -ne 0 ]; then echo -n "tranasm not found"; fi; echo "<tranasm>"
	@echo -n "<epocroot>"; if [ ! -d "$$EPOCROOT" ]; then echo -n "EPOCROOT='$$EPOCROOT' directory not found."; else echo -n "$$EPOCROOT"; fi; echo "</epocroot>"
	@echo -n "<raptorhome>"; if [ ! -d "$$RAPTOR_HOME" ]; then echo -n "RAPTOR_HOME='$$RAPTOR_HOME' directory not found."; else echo -n "$$RAPTOR_HOME"; fi; echo "</raptorhome>"
	@echo "</envcheck>"

	
	
# END TEST - Check FLMS
