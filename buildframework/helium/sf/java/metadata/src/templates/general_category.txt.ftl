<#--
============================================================================ 
Name        : summary.html.ftl 
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

    <#assign table_info = pp.loadData('com.nokia.helium.metadata.SQLFMPPLoader',
        "${dbPath}") >



<#assign logpath_table = table_info['select * from logfiles'] >
<#assign logpath_id = logpath_table?keys>
<#list logpath_id as logpath>
    <#assign component_table = table_info['select id, component from component where logPath_id=${logpath}'] >
    <#assign component_ids = component_table?keys?sort >
    <#list component_ids as component_id >
        component : ${component_table['${component_id}']} : logfile : ${logpath_table['${logpath}']}
    </#list>
</#list>
