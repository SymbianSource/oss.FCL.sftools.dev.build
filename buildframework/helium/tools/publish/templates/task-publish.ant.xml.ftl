<#--
============================================================================ 
Name        : task-publish.xml.ftl 
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
<?xml version="1.0"?>
<project name="task-publish" default="all" xmlns:hlm="http://www.nokia.com/helium">
    
    <target name="all">
        <#if (ant?keys?seq_contains('ccm.cache.xml'))>
        <hlm:createSessionMacro database="${ant['ccm.database']}" reference="publish.session" cache="${ant['ccm.cache.xml']}"/>
        <#else>
        <hlm:createSessionMacro database="${ant['ccm.database']}" reference="publish.session"/>
        </#if>
        <hlm:ccm verbose="false">
            <!-- Defining some session to use. -->
            <hlm:sessionset refid="publish.session"/>

            <hlm:addtask folder="${ant['publish.ccm.folder']}">
                <#list bom['/bom/content//task/id'] as task>
                <task name="${task?trim}"/>
                </#list>
            </hlm:addtask>
            <#if (!ant?keys?seq_contains('ccm.cache.xml'))>
            <hlm:close/>
            </#if>
        </hlm:ccm>
    </target>
    
    <!-- this is needed to include ccmtask support. -->
    <import file="${ant['helium.dir']}/helium.ant.xml"/>
</project>
