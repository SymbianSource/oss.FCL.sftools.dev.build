<#--
============================================================================ 
Name        : build_imaker_roms.mk.ftl 
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
###################################################################
#
# Generated build file.
#
#
###################################################################
<#assign deps=""/>
<#assign configid=1/>
<#list data as configuration>	
	<#list configuration?keys as config>
		<#list configuration[config] as target>
			<#assign deps="${deps} configuration${configid}_${config}_${target['target']}"/>
###################################################################
# building configuration${configid}_${config}_${target['target']}
###################################################################
configuration${configid}_${config}_${target['target']}:
	-imaker -f ${config} <#list target['variables']?keys as varname>"${varname}=${target['variables'][varname]}" </#list> ${target['target']}


		</#list>
	</#list>
	<#assign configid= configid + 1/>
</#list>


###################################################################
# Toplevel target
###################################################################
all: ${deps} ;

# End of config