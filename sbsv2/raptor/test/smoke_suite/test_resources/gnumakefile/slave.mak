# Envoke CED to install correct CommDB
#
 
do_nothing :
	rem do_nothing
 
 #
 # The targets invoked by abld 


MAKMAKE : 
	echo SLAVE.MAK MAKMAKE > slave_makmake_$(PLATFORM)_$(CFG).txt

RESOURCE : 
	echo SLAVE.MAK RESOURCE > slave_resource_$(PLATFORM)_$(CFG).txt

SAVESPACE : BLD

BLD : 
	echo SLAVE.MAK BLD > slave_bld_$(PLATFORM)_$(CFG).txt
 
FREEZE : 
	echo SLAVE.MAK FREEZE > slave_freeze_$(PLATFORM)_$(CFG).txt

LIB : 
	echo SLAVE.MAK LIB > slave_lib_$(PLATFORM)_$(CFG).txt

CLEANLIB : do_nothing
 
FINAL : 
	echo SLAVE.MAK FINAL >> slave_final_$(PLATFORM)_$(CFG).txt

CLEAN : 
	rm -f *.txt
 
RELEASABLES : 
	@echo $(DIRECTORY)/slave_makmake_$(PLATFORM)_$(CFG).txt
	@echo $(DIRECTORY)/slave_resource_$(PLATFORM)_$(CFG).txt
	@echo $(DIRECTORY)/slave_bld_$(PLATFORM)_$(CFG).txt
	@echo $(DIRECTORY)/slave_lib_$(PLATFORM)_$(CFG).txt
	@echo $(DIRECTORY)/slave_final_$(PLATFORM)_$(CFG).txt

