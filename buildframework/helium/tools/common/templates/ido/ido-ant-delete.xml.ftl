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
    <target name="all">
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
</project>
