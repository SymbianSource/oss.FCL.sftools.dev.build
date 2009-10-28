<#--
============================================================================ 
Name        : build_imaker_roms.ant.xml.ftl 
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
<project name="build_imaker_roms" default="all">
    <#assign dollar="$"/>
    <#assign romnumber=0/>
    
    <property name="imaker.temp.dir" location="${dollar}{build.drive}/epoc32/rombuild/imaker/temp"/>
    
    <target name="all">
        <#list data as configuration>
            <#if configuration['command'] == "switch_region">
                <echo>Switching to ${configuration['region']}.</echo>
                <unzip src="${dollar}{zips.loc.dir}/delta_${configuration['region']}_package.zip" 
                dest="${dollar}{build.drive}/" overwrite="true"/>
            </#if>
            
            <#assign romproperties=pp.newWritableSequence()/>
            <#if configuration['command'] == "imaker">
                <!--<parallel>-->
                <#list configuration['config']?keys as config>
                    <#list configuration['config'][config] as target>
                        <@pp.add seq=romproperties value="imaker.output.${romnumber}" />
                        <sequential>
                            <mkdir dir="${dollar}{imaker.temp.dir}/conf_${romnumber}"/>
                            <!--  outputproperty="imaker.output.${romnumber}" -->
                            <exec executable="${dollar}{imaker.command}" dir="${dollar}{build.drive}/">
                                <arg line="-f ${config?xml}"/>
                                <#list target['variables']?keys as varname>
                                    <arg value="${varname?xml}=${target['variables'][varname]?xml}"/>
                                </#list>
                                <arg value="${target['target']?xml}"/>
                                <arg value="WORKDIR=${dollar}{imaker.temp.dir}/conf_${romnumber}"/>
                            </exec>
                        </sequential>
                        <#assign romnumber=romnumber+1/>
                    </#list>
                </#list>
                <!--</parallel>
                <#list romproperties as romproperty>
                    <echo>${dollar}{${romproperty}}</echo>
                </#list>-->
            </#if>
        </#list>
    </target>

</project>