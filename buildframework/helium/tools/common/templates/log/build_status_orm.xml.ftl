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
    <#list table_info['jpa']['select p from Priority p'] as priority>
        <#assign priority_count = table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN  m.logFile  as l JOIN m.priority as p where LOWER(l.path) like \'%${logpath?lower_case}%\' and UPPER(p.priority) like \'%${priority.priority}%\''][0]>
        <#if (priority_count >= 0)>
            <${priority.priority?lower_case} count= "${priority_count}" />
        </#if>
    </#list>
</build-status>