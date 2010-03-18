<#--
============================================================================ 
Name        : ido-cmt-ant.xml.ftl 
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
<project name="ido-cmt-ant" default="all" xmlns:hlm="http://www.nokia.com/helium">
<import file="${ant['helium.dir']}/helium.ant.xml"/>
<#assign targetlist=""/>
<#assign cmtid=1/>
    <#list data?keys as component>
    <#if (cmtid > 1)>
    <#assign targetlist="${targetlist}" + ","/>
    </#if>
    <basename property="componentbase${cmtid}" file="${data[component]}"/>
    <hlm:argSet id="cmttool.refid.${cmtid}">
        <hlm:arg name="input" value="${data[component]}" />
        <hlm:arg name="output" value="${ant['build.log.dir']}/${ant['build.id']}_${ant['ido.name']}_${r'$'}{componentbase${cmtid}}_${cmtid}.txt" />
        <hlm:arg name="pattern" value="**/*.h,**/*.cpp" />
    </hlm:argSet>

    <target name="cmt-${cmtid}">
        <hlm:toolMacro name="cmt">
            <toolvarset refid="cmttool.refid.${cmtid}"/>
        </hlm:toolMacro>
    </target>
    <#assign targetlist="${targetlist}" + "cmt-${cmtid}"/>
    <#assign cmtid=cmtid+1/>
    </#list>
    <target name="all" depends="${targetlist}" >
    </target>
</project>