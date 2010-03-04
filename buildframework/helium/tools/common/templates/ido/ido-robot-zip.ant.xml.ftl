<#--
============================================================================ 
Name        : ido-robot-zip.ant.xml.ftl 
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
<project name="ido-zip" default="all">
    <target name="all">
        <delete file="${ant['build.output.dir']}/s60Sources.7z" failonerror="false"/>
        <#if ((data?keys?size > 0) && (ant['do.robot.release']?split(';')?size > 0))>
            <#list data?keys as name>
                <#list ant['do.robot.release']?split(',') as project>
                    <#if name?replace('\\', '/')?lower_case?contains("/${project}/${project}"?lower_case)>
                    <#-- 7za u test.7z  output/analysisdata/ -->
                    <exec executable="7za" dir="${name}/../">
                        <arg value="u"/>
                        <arg value="-xr!*/internal/*"/>
                        <arg value="-xr!*/doc/*"/>
                        <arg value="-xr!_ccmwaid.inf"/>
                        <arg value="-xr!abld.bat"/>
                        <arg value="${ant['build.output.dir']}/s60Sources.7z"/>
                        <arg value="${name?split("/")?last}/"/>
                    </exec>                    
                    </#if>
                </#list>
            </#list>
        </#if>
        <copy todir="${ant['s60.build.robot.path']}" file="${ant['build.output.dir']}/s60Sources.7z" failonerror="false" />        
    </target>
</project>
