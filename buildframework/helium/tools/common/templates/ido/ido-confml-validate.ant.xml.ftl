<#--
============================================================================ 
Name        : ido-confml-validate.ant.xml.ftl 
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
<?xml version="1.0"?>
<project name="validate-confml" default="validate-confml-file">
    
    <target name="validate-confml-file">
        <#if os?lower_case?starts_with('win')>
            <#assign exe_file="cmd.exe"/>
        <#else>
            <#assign exe_file="bash"/>
        </#if>
        <sequential>
            <exec executable="${exe_file}" dir="${ant['build.drive']}/epoc32/tools" failonerror="false" output="${ant['post.log.dir']}/${ant['build.id']}_validate_confml.log">
                <#if os?lower_case?starts_with('win')>
                <arg value="/c"/>
                <arg value="cone.cmd"/>
                <#else>
                <arg value="cone"/>
                </#if>
                <arg value="validate" />                            
                <#list table_info['native:java.lang.String']['select distinct w.member FROM WhatLogEntry w where w.member like \'%.confml\''] as confmlfile>
                <arg value="--confml-file"/> 
                <arg value="${confmlfile}" />
                </#list>
                <#list table_info['native:java.lang.String']['select distinct w.member FROM WhatLogEntry w where w.member like \'%.crml\''] as crmlfile>
                <arg value="--implml-file"/> 
                <arg value="${crmlfile}" />
                </#list>
                <arg value="--report-type"/> 
                <arg value="xml" />
                <arg value="--report"/>
                <arg value="${ant['post.log.dir']}/${ant['build.id']}_validate_confml.xml" />
            </exec>
        </sequential>
    </target>
    
</project>


