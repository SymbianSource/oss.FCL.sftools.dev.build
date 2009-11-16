# Envoke CED to install correct CommDB
#
 
do_nothing :
	rem do_nothing
 
 #
 # The targets invoked by abld 


MAKMAKE : 
	echo SLAVE.MAK MAKMAKE >> master_makmake_$(PLATFORM)_$(CFG).txt

RESOURCE : 
	echo SLAVE.MAK RESOURCE >> master_resource_$(PLATFORM)_$(CFG).txt

SAVESPACE : BLD

BLD : 
	echo SLAVE.MAK BLD >> master_bld_$(PLATFORM)_$(CFG).txt
 
FREEZE : 
	echo SLAVE.MAK FREEZE >> master_freeze_$(PLATFORM)_$(CFG).txt

LIB : 
	echo SLAVE.MAK LIB >> master_lib_$(PLATFORM)_$(CFG).txt

CLEANLIB : do_nothing
 
FINAL : 
	echo SLAVE.MAK FINAL >> master_final_$(PLATFORM)_$(CFG).txt

CLEAN : 
	rm -f *.txt
 
RELEASABLES : 
	@echo $(DIRECTORY)/master_makmake_$(PLATFORM)_$(CFG).txt
	@echo $(DIRECTORY)/master_resource_$(PLATFORM)_$(CFG).txt
	@echo $(DIRECTORY)/master_bld_$(PLATFORM)_$(CFG).txt
	@echo $(DIRECTORY)/master_lib_$(PLATFORM)_$(CFG).txt
	@echo $(DIRECTORY)/master_final_$(PLATFORM)_$(CFG).txt

