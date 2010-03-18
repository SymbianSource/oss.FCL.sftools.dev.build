<#--
============================================================================ 
Name        : image_conf_buildinfo.mk.ftl 
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
# Helium - iMaker buildinfo template.
#
# This is a generated file please to not edit! 
#
##########################################################################

<#assign dollar="$"/>
<#assign properties = ['build.number', 'build.id', 'minor.version', 'major.version', 'build.output.dir', 'release.images.dir', 'fota.a.build']/>
<#list properties as key>
<#if ant?keys?seq_contains(key)>
	<#if key?ends_with(".dir")>
${key?upper_case?replace(".", "_")} = ${dollar}(call upddrive,${dollar}(subst \,/,${ant[key]}))
	<#else> 
${key?upper_case?replace(".", "_")} = ${ant[key]}
	</#if>
<#else>
$(warning '${key}' is not a valid Helium property.)
</#if>
</#list>

# Simple update for FOTA.
MINOR_VERSION:=${r'$'}(MINOR_VERSION)${r'$'}(FOTA_A_BUILD)
