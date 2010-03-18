<#--
============================================================================ 
Name        : macro.ftl 
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
<#setting number_format="0">
<#macro numberof regex type>
    <#assign count = 0>
<#if doc?? >
    <#list doc.logSummary.log as lognode>
        <#if lognode.@filename[0]?matches(regex)>
            <#assign count = count + lognode.build[".//message[@priority='${type}']"]?size>
        </#if>
    </#list>
</#if>
${count}</#macro>
<#macro printfaults regex type>
</#macro>

<#macro printcomponents regex>
</#macro>
<#macro printall type>
    <#if doc?? >
        <#assign componentname="">
        <#assign components="">
        <#assign componenterrors = 0>
        <#assign totalerrors = 0>
        <#assign totalwarnings = 0>
        <#assign componentwarnings = 0>
        <#assign componentcriticals = 0>
        <#assign totalcriticals = 0>
        <#assign ls=doc.logSummary["//task/task/@name"]?sort>
        <!-- print all the fault info -->
        <faults>
        <#list ls as task>
            <#assign currenttask=task?parent>
            <#assign parenttask=currenttask?parent>
            <#assign currentcomponentname="${task}">
            <#if componentname == "">
                <#assign componentname="${task?parent.@name}">
                <#assign components="${componentname}">
            </#if>
            <#if componentname != currentcomponentname>
            <component>
                <name>${componentname}</name>
                <total severity="error">${componenterrors}</total>
                <total severity="warning">${componentwarnings}</total>
            </component>
                <#assign componentname=currentcomponentname>
                <#assign components= components + ",${componentname}">
                <#assign totalerrors = totalerrors + componenterrors>
                <#assign totalwarnings = totalwarnings + componentwarnings>
                <#assign totalcriticals = totalcriticals + componentcriticals>
                <#assign componenterrors = 0>
                <#assign componentwarnings = 0>
                <#assign componentcriticals = 0>
            </#if>
            <#assign componenterrors = componenterrors + currenttask[".//message[@priority='error']"]?size>
            <#assign componentwarnings = componentwarnings + currenttask[".//message[@priority='warning']"]?size>
            <#assign componentcriticals = componentcriticals + currenttask[".//message[@priority='critical']"]?size>
        </#list>
        <#if componentname!= "">
            <component>
                <name>${componentname}</name>
                <total severity="error">${componenterrors}</total>
                <total severity="warning">${componentwarnings}</total>
                <total severity="critical">${componentcriticals}</total>
            </component>
        </#if>
            <!-- print summary of the errors -->
            <#assign totalerrors = totalerrors + componenterrors>
            <#assign totalwarnings = totalwarnings + componentwarnings>
            <total severity="error">${totalerrors}</total>      
            <total severity="warning">${totalwarnings}</total>
            <total severity="warning_rvct_other">${totalwarnings}</total>
            <!-- todo update to calculate the correct value -->
            <total severity="warning_rvct_bad">${totalcriticals}</total>
        </faults>
        <components>
        <!-- all components -->
        <#list components?split(",") as component >
            <#if component != "">
            <component>${component}</component>
            </#if>
        </#list>
        </components>
    </#if>
</#macro>
<#assign schema_version=20/>