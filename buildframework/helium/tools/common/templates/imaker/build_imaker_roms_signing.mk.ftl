<#--
============================================================================ 
Name        : build_imaker_roms_signing.mk.ftl 
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
<#assign dollar="$"/>

IMAKER_WORKDIR=\epoc32\rombuild\imaker_temp

${dollar}(IMAKER_WORKDIR):
	-mkdir ${dollar}(IMAKER_WORKDIR)


###################################################################
#
# Generated build file.
#  * Implements Electic Cloud signing optimizations.
#
###################################################################
<#assign deps_image=""/>
<#assign deps_all=""/>
<#assign configid=1/>
<#assign romid=0/>
<#list data as configuration>

	<#if configuration['command'] == "switch_region">
###################################################################
# Config${configid} : Switching region (${configuration['region']})
###################################################################

build-configuration${configid}: <#if (configid-1 > 0) >build-configuration${configid-1}</#if>
	@echo Switching to ${configuration['region']}.
	-@unzip -o -d $(subst \,/,$(EPOCROOT)) ${ant['zips.loc.dir']}/delta_${configuration['region']}_package.zip 

   		<#assign deps_all="build-configuration${configid}"/>
 		<#assign configid= configid + 1/>
	</#if>

	<#if configuration['command'] == "imaker">
		<#assign deps_conf_image=""/>
		<#assign deps_conf_signing=""/>
		<#list configuration['config']?keys as config>
			<#list configuration['config'][config] as target>
				<#assign deps_conf_image="${deps_conf_image} configuration${configid}_${config}_${target['target']}"/>
				<#assign deps_conf_signing="${deps_conf_signing} signing_configuration${configid}_${config}_${target['target']}"/>
###################################################################
# building configuration${configid}_${config}_${target['target']}
###################################################################
configuration${configid}_${config}_${target['target']}:  ${dollar}(IMAKER_WORKDIR) <#if (configid-1 > 0) >build-configuration${configid-1}</#if>
	@echo === config_${configid} == configuration${configid}_${config}_${target['target']}
	@echo -- imaker -f ${config} image ... ${target['target']}
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"
	-imaker -f ${config} <#list target['variables']?keys as varname>"${varname}=${target['variables'][varname]}" </#list> ${target['target']}-image  WORKDIR=${dollar}(IMAKER_WORKDIR)/conf_${romid}
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""

#pragma runlocal
signing_configuration${configid}_${config}_${target['target']}: ${dollar}(IMAKER_WORKDIR) all-image-conf${configid}
	@echo === config_${configid} == signing_configuration${configid}_${config}_${target['target']}
	@echo -- imaker -f ${config} elf2flash ... ${target['target']}
	-@perl -e "print '++ Started at '.localtime().\"\n\""
	-@perl -e "use Time::HiRes; print '+++ HiRes Start '.Time::HiRes::time().\"\n\";"	
	-imaker -f ${config} <#list target['variables']?keys as varname>"${varname}=${target['variables'][varname]}" </#list> ${target['target']}-e2flash  WORKDIR=${dollar}(IMAKER_WORKDIR)/conf_${romid}
	-@perl -e "use Time::HiRes; print '+++ HiRes End '.Time::HiRes::time().\"\n\";"
	-@perl -e "print '++ Finished at '.localtime().\"\n\""

		<#assign romid= romid + 1/>
            </#list>
		</#list>

        <#if deps_conf_image != "" && deps_conf_signing!= "" >
all-image-conf${configid}: ${deps_conf_image} ;
build-configuration${configid}: ${deps_conf_signing} ;
            <#assign deps_all="build-configuration${configid}"/>
            <#assign configid= configid + 1/>
        </#if>
    </#if>
</#list>


###################################################################
# Toplevel target
###################################################################

all: ${deps_all} ;

# End of config