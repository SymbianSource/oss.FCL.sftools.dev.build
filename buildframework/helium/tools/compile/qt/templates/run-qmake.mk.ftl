<#--
============================================================================ 
Name        : run-qmake.mk.ftl 
Part of     : Helium 

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================
--> 
##########################################################################
#
# run-qmake-${ant['sysdef.configuration']}.mk
#
##########################################################################

<#list data["//unit/@proFile/.."] as unit>
##########################################################################
/${unit.@bldFile}/bld.inf: /${unit.@bldFile}/${unit.@proFile}
	@echo cd /${unit.@bldFile} ^&^& qmake -listgen <#if unit.@qmakeArgs[0]??>${unit.@qmakeArgs}<#else>${ant['qt.qmake.default.args']}</#if><#if "${ant['build.system']?lower_case}" = 'sbs-ec'> -spec symbian-sbsv2</#if> ${unit.@proFile}
	-@cd /${unit.@bldFile} && qmake -listgen <#if unit.@qmakeArgs[0]??>${unit.@qmakeArgs}<#else>${ant['qt.qmake.default.args']}</#if> ${unit.@proFile}

all:: /${unit.@bldFile}/bld.inf


</#list>

##########################################################################

all:: ; @echo All done 

##########################################################################
