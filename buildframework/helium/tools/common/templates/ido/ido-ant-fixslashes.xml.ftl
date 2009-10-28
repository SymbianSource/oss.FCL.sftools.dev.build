<#--
============================================================================ 
Name        : ido-ant-copy.xml.ftl 
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
<project name="ido-ant-fixslashes" default="all">
    <target name="all">
        <parallel threadCount="${r'$'}{number.of.threads}">
<#assign scanid=1/>
        <#list data?keys as component>
            <sequential>
                  <exec executable="perl" dir="${component}" output="${ant['build.log.dir']}/fixslashes_${ant['ido.name']}.log" append="true" failonerror="false">
                    <arg value="${ant['ido.common.config.dir']}/scripts/fixslashes_test.pl"/>
                    <arg line="-verbose -recursive -dir ${data[component]}"/>
                   </exec>
                  <exec executable="perl" dir="${component}" output="${ant['build.log.dir']}/fixrsg_${ant['ido.name']}.log" append="true" failonerror="false">
                    <arg value="${ant['ido.common.config.dir']}/scripts/fixrsg.pl"/>
                    <arg line="-v ${data[component]}"/>
                   </exec>
            </sequential>
            <#assign scanid=scanid+1/>
        </#list>
        </parallel>
    </target>
</project>