<#ftl ns_prefixes={"qt":"http://www.nokia.com/qt"}>  
<#--
============================================================================ 
Name        : run-qmake.ant.xml.ftl 
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
<project name="run-qmake-${ant['sysdef.configuration']}" default="all">
    
    <target name="all">
        <parallel threadCount="${r'$'}{number.of.threads}">
    <#list data["//unit/@proFile/.."] + data["//unit/@qt:proFile/.."] as unit>
        <#assign prefix="qt:" />
        <#if unit.@proFile[0]??>
            <#assign prefix="" />
        </#if>
            <sequential>
                <echo>Running qmake for ${unit.@bldFile}/${unit['@${prefix}proFile'][0]?xml}</echo>
                <if>
                    <available file="${r'$'}{build.drive}/${unit.@bldFile}" type="dir"/>
                    <then>
                        <exec executable="cmd" osfamily="windows" dir="${r'$'}{build.drive}/${unit.@bldFile}" failonerror="false">
                            <arg value="/C"/>
                            <arg value="qmake"/>
                            <arg value="-listgen"/>
                            <#if unit['@${prefix}qmakeArgs'][0]??>
                            <arg line="${unit['@${prefix}qmakeArgs'][0]?xml}"/>
                            <#else>
                            <arg line="${ant['qt.qmake.default.args']?xml}"/>
                            </#if>
                            <arg value="${unit['@${prefix}proFile'][0]?xml}"/>
                        </exec>
                        <exec osfamily="unix" executable="sh" dir="${r'$'}{build.drive}/${unit.@bldFile}" failonerror="false">
                            <arg value="${ant['epocroot']}/epoc32/tools/qmake"/>
                            <arg value="-listgen"/>
                            <#if unit['@${prefix}qmakeArgs'][0]??>
                            <arg line="${unit['@${prefix}qmakeArgs'][0]?xml}"/>
                            <#else>
                            <arg line="${ant['qt.qmake.default.args']?xml}"/>
                            </#if>
                            <arg value="${unit['@${prefix}proFile'][0]?xml}"/>
                        </exec>
                    </then>
                    <else>
                       <echo message="ERROR: Directory ${r'$'}{build.drive}/${unit.@bldFile} doesn't exist."/>
                    </else>
                </if>
            </sequential>
    </#list>
        </parallel>
    </target>
    
</project>
