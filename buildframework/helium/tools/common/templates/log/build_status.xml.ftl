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
    <#assign table_info = pp.loadData('com.nokia.helium.metadata.SQLFMPPLoader',
        "${dbPath}") >
<#assign priority_table = table_info['select * from priority'] >
<#assign priority_ids = priority_table?keys>

<#list priority_ids as priority>
    <#assign priority_count = table_info['select count(data) as COUNT from metadata where priority_id = ${priority} and logpath_id in (select id from logfiles where path like \'%${logpath}%\')'][0]['COUNT'] >
    <#if (priority_count >= 0)>
        <${priority_table['${priority}']?lower_case} count= "${priority_count}" />
    </#if>
</#list>
</build-status>