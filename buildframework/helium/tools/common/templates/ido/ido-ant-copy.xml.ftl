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
<project name="ido-ant-copy" default="all">
    <target name="delete">
        <parallel threadCount="${r'$'}{number.of.threads}">
        <#list data?keys as component>
            <sequential>
                <#if ant?keys?seq_contains('ido.keep.old')>
                <delete dir="${data[component]}_old" failonerror="false"/>
                <move file="${data[component]}" todir="${data[component]}_old" failonerror="false"/>
                <#else>
                <delete dir="${data[component]}" failonerror="false"/>
                </#if>
            </sequential>
        </#list>
        </parallel>
    </target>
    
    <target name="copy">
        <#list data?keys as component>
            <mkdir dir="${data[component]}"/>
        </#list>
        <parallel threadCount="${r'$'}{number.of.threads}">
        <#list data?keys as component>
            <sequential>
                <copy todir="${data[component]}" verbose="false" failonerror="false" overwrite="true">
                    <fileset dir="${component}" casesensitive="false" >
                        <exclude name="**/_ccmwaid.inf"/>
                        <#if (!ant?keys?seq_contains('keep.internals'))>
                        <exclude name="**/internal/**"/>
                        </#if>
                        <exclude name="**/.hg/**"/>
                        <exclude name="**/.svn/**"/>
                    </fileset>
                </copy>
                <#-- Below operation is not required on linux as copy task will changes 
                the file permissions to write mode -->
                <exec executable="attrib" osfamily="windows" dir="${data[component]}">
                    <arg line="-R /S /D .\*"/>
                </exec>
            </sequential>
        </#list>
        </parallel>
    </target>
    
    <target name="all" depends="delete,copy" />
</project>
