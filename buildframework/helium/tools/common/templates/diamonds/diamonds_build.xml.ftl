<#--
============================================================================ 
Name        : diamonds_build.xml.ftl 
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
<build>
    <category>${ant["build.family"]?xml}</category>
    <name>${ant["build.id"]?xml}</name>
    <#if ant?keys?seq_contains("ecc.project")>
    <project>${ant["ecc.project"]?xml}</project>
    <schedule>${ant["ecc.schedule"]?xml}</schedule>
    <timebox>${ant["ecc.ido.branch"]?xml}</timebox>
    <procedure>${ant["ecc.procedure"]?xml}</procedure>
    <includeinstats>${ant["ecc.include.in.stats"]?xml}</includeinstats>
    </#if>
    <#if ant?keys?seq_contains("build.start.time")><started>${ant["build.start.time"]?xml}</started></#if>
    <#if ant?keys?seq_contains("build.end.time")><finished></finished></#if>
        <creator>${ant["env.USERNAME"]?xml}</creator>
        <hostname>${ant["env.COMPUTERNAME"]?xml}</hostname>
        <product>${ant["build.name"]?xml}</product>
        <build_system>${ant["build.system"]?xml}</build_system>
    <#if ant?keys?seq_contains("env.NUMBER_OF_PROCESSORS")><processor_count>${ant["env.NUMBER_OF_PROCESSORS"]?xml}</processor_count></#if>
</build>