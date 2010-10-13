<#--
============================================================================ 
Name        : ido-codescanner.ant.xml.ftl 
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
<project name="ido-codescanner" default="gen-codescanner-report" xmlns:hlm="http://www.nokia.com/helium">
    <target name="gen-codescanner-report">
        <parallel>
        <#assign componentLXRPath = "">
        <#assign no_of_components = data?size>
        <#list data?keys as component>
        <#if (no_of_components > 1)>
            <#assign componentName = data[component]?split("/")?last>
            <hlm:codescanner    format="${ant['ido.codescanner.output.type']}"
                                configuration="${ant['ido.codescanner.config']}"
                                sourcedir="${ant['internal.codescanner.drive']}/${componentName}"
                                dest="${ant['ido.codescanner.output.dir']}/${componentName}"
                                lxrurl="${ant['codescanner.lxr.source.url']}${data[component]?substring(ant['build.drive']?length)}/"
                                failonerror="false"/>
        <#else>
            <hlm:codescanner    format="${ant['ido.codescanner.output.type']}"
                            configuration="${ant['ido.codescanner.config']}"
                            sourcedir="${ant['internal.codescanner.drive']}\"
                            dest="${ant['ido.codescanner.output.dir']}"
                            lxrurl="${ant['codescanner.lxr.source.url']}${data[component]?substring(ant['build.drive']?length)}/"
                            failonerror="false"/>
        </#if>
        </#list>
        </parallel>
    </target>
</project>
