<#--
============================================================================ 
Name        : build.xml.ftl 
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
    <category>${ant["build.family"]}</category>
    <name>${ant["build.id"]}</name>
    <#if diamonds?keys?seq_contains("build.start.time")><started>${diamonds["build.start.time"]}</started></#if>
    <#if diamonds?keys?seq_contains("build.end.time")><finished>${diamonds["build.end.time"]}</finished></#if>
        <creator>${ant["env.USERNAME"]}</creator>
        <hostname>${ant["env.COMPUTERNAME"]}</hostname>
        <product>${ant["build.name"]}</product>
        <build_system>${ant["build.system"]}</build_system>
    <#if ant?keys?seq_contains("env.NUMBER_OF_PROCESSORS")><processor_count>${ant["env.NUMBER_OF_PROCESSORS"]}</processor_count></#if>
</build>