<#--
============================================================================ 
Name        : modificationset.log.xml.ftl 
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
<?xml version="1.0" encoding="utf-8"?>
<log filename="${ant['build.log.dir']}/${ant['build.id']}_modificationset.xml">
    <build>
<#list doc["./modificationset/project"] as project>
        <#assign status=""/>
        <#if project.@new?lower_case == "true">
            <#assign status="baseline updated"/>
        </#if>
        <task name="${project.@id} (${status})">
            <task name="Tasks">
            <#list project["./task"] as task>
                <message priority="info"><![CDATA[${task.@id?html}: ${task.@description?html}]]></message>
            </#list>
            </task>
            <task name="Objects">
            <#list project["./object"] as task>
                <message priority="info"><![CDATA[${task.@id?html}: ${task.@user?html}: ${task.@status?html}:${task.@description?html}]]></message>
            </#list>
            </task>
            <task name="Errors">
            <#list project["./error"] as task>
                <message priority="error"><![CDATA[${task.@description?html}]]></message>
            </#list>
            </task>
        </task>
</#list>
    </build>
</log>
