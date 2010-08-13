<#--
============================================================================ 
Name        : email.html.ftl 
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
<build-status>
    <#assign table_info = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader',
        "${dbPath}") >
    <#assign convertedLogFile = "${logpath}"?replace("\\","/")>
    <#list table_info['jpa']['select p from Severity p'] as severity>
        <#assign severity_count = table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN  m.logFile l where LOWER(l.path)=\'${convertedLogFile?lower_case}\' and m.severityId=${severity.id}'][0]>
        <#if (severity_count >= 0)>
            <${severity.severity?lower_case} count="${severity_count}" />
        </#if>
    </#list>
</build-status>