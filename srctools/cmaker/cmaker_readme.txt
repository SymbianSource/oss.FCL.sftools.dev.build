*********************************************************************************************************************************
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies). 
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Symbian Foundation License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.symbianfoundation.org/legal/sfl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description:
* cmaker makefile installation.
* cMaker - a Make-based configuration export tool 

Setting up environment to use this version of cmaker
====================================================

- Extract env
- Merge the makefiles from config_maker\config to the root config project

Usage of cmaker
===============

At the root of the config folder, type:

cmaker [target] [ACTION=<action>] [NCP=[ncp number][,ncp number]*] [S60=[s60 number][,s60 number]*] [PPD=[ppd number][,ppd number]*] 

action: actions are found from \epoc32\rom\cmaker\functions.ml
 * export = copy the given target from source
 * clean = delete the target
 * what = print the target
 * what_deps = print source target
 
Default ACTION is export. 

The cmaker can be called without any parameters, in which case the makefile in the current folder is included first 
and the first target defined in that makefile is executed.

Example usage:
--------------

1) Export all NCP53 configs 
>cd \config\
>cmaker ncp53_all NCP=53
or 
>cd \config\ncp_config\ncp5.3_config
>cmaker

2) 'What' list of all NCP53 and 5332 and dependent config exports 	
>cd \config\
>cmaker NCP=53 S60=32 ACTION=what

3) What_deps list of all NCP53 and 5332 config exports
>cd \config\
>cmaker NCP=53 S60=32 ACTION=what_deps

4) Clean all NCP71 and PPD5332 config exports
>cd \config\
>cmaker NCP=53 S60=32 ACTION=clean


=== Configuring cmaker ===

=== Project makefile ===
Example project makefile that defines ncp52_config as a project target. The intention here is that the CM Synergy project name is always a target in cmaker, which can be exported. The other defined targets are there to define dependencies.
{{{
# NCP5.2 config level configuration makefile


#Define this platform as default if nothing is defined
ifeq (,$(NCP))
NCP += 52
$(warning Ncp platform not defined (E.g. NCP=53)! Using $(NCP))
endif

ifeq (52,$(findstring 52,$(NCP)))
MAKEFILE = /config/ncp_config/ncp5.2_config/makefile
	
# Place the first target as the default target which is executed from this level
ncp52_all    :: ncp52_config
ncp52_config ::
ncp52_config :: ncp_config
ncp_all      :: ncp52_all
	       
include include_template.mk
	
endif
}}}

=== export.mk ===
Example folder exporting makefile. The export.mk defines source and target (files|folder) as make variables (e.g. DATAFILES in the example). Then the example uses a add-files macro to add DATAFILES as targets for the system (e.g. $(call addfiles, $(DATAFILES), ncp52_config-data) in the example). This makes every target file in DATAFILES a make target, and defines a dependency from ncp_config-data to each target file. So if you run ncp_config-data target you would actually run every target file defined in DATAFILES.

{{{
# NCP5.2 config's actual configuration export makefile

MAKEFILE = 	/config/ncp_config/ncp5.2_config/config/export.mk
$(call push,MAKEFILE_STACK,$(MAKEFILE))

SECENVDIR = 	/ncp_sw/corecom/sec_env/bin_NCP_5_1/
	
DATAFILES =	$(MAKEFILEDIR)data/base_directory.mke       /epoc32/include/oem/                  \
            $(MAKEFILEDIR)data/HWRMLightsPolicy.ini     /epoc32/data/Z/private/101f7a02/      \
            $(MAKEFILEDIR)data/tcpip_52.ini             /epoc32/data/z/private/101F7989/esock/
			                                                                                        		
INCFILES =	$(MAKEFILEDIR)inc/*.hrh                   /epoc32/include/oem/	          \
		        $(MAKEFILEDIR)inc/*.hrh                   /epoc32/include/config/ncp52/   \
		        $(MAKEFILEDIR)inc/adaptation_conf.h       /epoc32/include/internal/               		
		                                                                                                		
ROMFILES =	$(MAKEFILEDIR)rom/config/base_romfiles.txt 		/epoc32/rombuild/ 					\
		$(MAKEFILEDIR)rom/config/rapido.ini 			/epoc32/rombuild/ 					\
		$(MAKEFILEDIR)rom/config/x_conf_rapido_ncp52.txt 	/epoc32/rom/config/ncp52/ 				\
		$(MAKEFILEDIR)rom/config/*.axf 				/epoc32/rom/config/ncp52/ 				\
		$(MAKEFILEDIR)rom/config/*.mk 				/epoc32/rom/config/ncp52/ 				\
		$(MAKEFILEDIR)rom/variant/*.* 				/epoc32/rom/config/ncp52/ 				\
		$(MAKEFILEDIR)rom/include/*.* 				/epoc32/rom/config/ncp52/ 				\
		$(MAKEFILEDIR)rom/include/*.* 				/epoc32/rom/include/ 					\
		$(SECENVDIR)pa_cmt_NCP_5_1.bin				/epoc32/rom/config/ncp52/ 				\
		$(SECENVDIR)ppa_cmt_NCP_5_1.bin				/epoc32/rom/config/ncp52/
			
TOOLFILES =	$(MAKEFILEDIR)tools/*.* 				/epoc32/tools/ 						\
		$(MAKEFILEDIR)tools/rom/image.txt 			/epoc32/tools/rom/
	
ncp52_config-data :: 
	
$(call addfiles, $(DATAFILES), ncp52_config-data)
		
ncp52_config-inc :: 
	
$(call addfiles, $(INCFILES), ncp52_config-inc)
	
ncp52_config-rom :: 
	
$(call addfiles, $(ROMFILES), ncp52_config-rom)
	
ncp52_config-tools :: 
	
$(call addfiles, $(TOOLFILES), ncp52_config-tools)

ncp52_config :: ncp52_config-data ncp52_config-inc ncp52_config-rom ncp52_config-tools

$(call popout,MAKEFILE_STACK)
}}}
