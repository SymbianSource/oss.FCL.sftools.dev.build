<#--
============================================================================ 
Name        : ido-cenrep-gen.xml.ftl 
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
<#assign table_info = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader',
        "${dbPath}") >

<project name="cenrep-generation" default="all">
    <#if os?lower_case?starts_with('win')>
        <#assign exe_file="cmd.exe"/>
    <#else>
        <#assign exe_file="bash"/>
    </#if>
    <target name="ido-cenrep-generation">
        <sequential>
            <#list table_info['native:java.lang.String']['select distinct w.member FROM WhatLogEntry w where w.member like \'%.confml\''] as confmlfile>
            <exec executable="${exe_file}" dir="${ant['build.drive']}/epoc32/tools" failonerror="false" output="${ant['post.log.dir']}/${ant['build.id']}_cenrep.cone.log">
                <#if os?lower_case?starts_with('win')>
                <arg value="/c"/>
                <arg value="cone.cmd"/>
                <#else>
                <arg value="cone"/>
                </#if>
                <arg value="generate" />                            
                <arg value="-p"/>
                <arg value="${ant['build.drive']}\epoc32\rom\config\assets\s60" />
                <arg value="-o" />
                <arg value="${ant['build.drive']}\epoc32\release\winscw\urel\z" />
                <arg value="-c"/>
                <arg value="root.confml" />
                <arg value="-i"/> 
                <arg value="${confmlfile}" />
            </exec>
            </#list>
        </sequential>
    </target>
    
    <target name="all" depends="ido-cenrep-generation" />
</project>


