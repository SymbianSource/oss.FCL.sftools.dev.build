<#--
============================================================================ 
Name        : release_ccm_project.ant.xml.ftl 
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
<?xml version="1.0" encoding="utf-8"?>
<project name="release-ccm-project" xmlns:hlm="http://www.nokia.com/helium">
    <import file="${r'$'}{helium.dir}/helium_preinclude.ant.xml" />

    <target name="all" depends="get-ccm-password">
    <#list data.release.project as project>
        <echo>${project.@database} - ${project.@name} - ${project.@dir} - ${project.@role}</echo>
        <#if (ant?keys?seq_contains('ccm.cache.xml'))>
        <hlm:createSessionMacro database="${project.@database}" reference="publish.session" cache="${ant['ccm.cache.xml']}"/>
        <#else>
        <hlm:createSessionMacro database="${project.@database}" reference="publish.session"/>
        </#if>
        <hlm:ccm verbose="true">
            <!-- Defining some session to use. -->
            <hlm:sessionset refid="publish.session"/>
            <role role="${project.@role}" />
            <workarea project="${project.@name}" maintain="false" recursive="true" />
        </hlm:ccm>
        <trycatch>
            <try>
                <hlm:rebaseanddeconf database="${project.@database}"
                    password="${r'$'}{ccm.user.password}" 
                    verbosity="1"
                    ccmProject="${project.@name}"
                    release="${project.@release}" 
                    releaseBaseline="yes" 
                    skipDeconfigure="false" />
            </try>
            <finally>
                <hlm:ccm verbose="true">
                    <hlm:sessionset refid="publish.session"/>
                    <update project="${project.@name}" />
                    <workarea project="${project.@name}" path="${project.@dir}" pst="${project.@pst}" maintain="true" recursive="true" />
                    
                    <#if (!ant?keys?seq_contains('ccm.cache.xml'))>
                    <hlm:close/>
                    </#if>
                </hlm:ccm>
            </finally>
        </trycatch>
    </#list>
    </target>
        
    <import file="${r'$'}{helium.dir}/helium.ant.xml" />
</project>
