<#ftl ns_prefixes={"qt":"http://www.nokia.com/qt"}>  
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

<#list data["//unit/@proFile/.."] + data["//unit/@qt:proFile/.."] as unit>
    <#assign prefix="qt:" />
    <#if unit.@proFile[0]??>
        <#assign prefix="" />
    </#if>
##########################################################################
/${unit.@bldFile}/bld.inf: /${unit.@bldFile}/${unit['@${prefix}proFile'][0]}
	@echo cd /${unit.@bldFile} ^&^& qmake -listgen <#if unit['@${prefix}qmakeArgs'][0]??>${unit['@${prefix}qmakeArgs'][0]}<#else>${ant['qt.qmake.default.args']}</#if><#if "${ant['build.system']?lower_case}" = 'sbs-ec'> -spec symbian-sbsv2</#if> ${unit['@${prefix}proFile'][0]}
	-@cd /${unit.@bldFile} && qmake -listgen <#if unit['@${prefix}qmakeArgs'][0]??>${unit['@${prefix}qmakeArgs'][0]}<#else>${ant['qt.qmake.default.args']}</#if> ${unit['@${prefix}proFile'][0]}

all:: /${unit.@bldFile}/bld.inf


</#list>

##########################################################################

all:: ; @echo All done 

##########################################################################
