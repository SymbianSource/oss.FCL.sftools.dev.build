<#--
============================================================================ 
Name        : zip-ant-wa-copy.xml.ftl 
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
<project name="zip-wa-ant-copy" default="all">
    <target name="all">
        <#list data?keys as component>
            <sequential>
                <#assign ba_path= data[component]?substring(3)/>
                <zip destfile="${ant['zip.wa.file']}" update="true" excludes="_ccmwaid.inf">
                    <zipfileset dir="${component}" prefix="${ba_path}"/>
                 </zip>
            </sequential>
        </#list>
    </target>
</project>
