<#--
============================================================================ 
Name        : macro.ftl 
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
<#include "diamonds_header.ftl"> 

<#setting number_format="0">

    <#assign table_info = pp.loadData('com.nokia.helium.metadata.SQLFMPPLoader',
        "${dbPath}") >
    <#assign priority_table = table_info['select * from priority'] >
    <#assign logpath_table = table_info['select * from logfiles'] >
    <#assign priority_ids = priority_table?keys>
    <#assign logpath_id = logpath_table?keys>
    <#assign components = table_info['select * from component where logPath_id in (select id from logfiles where (path like \'%_compile.log\'  and path not like \'%_clean_compile.log\'))'] >
    <faults>
        <total severity="error">${table_info['select count(data) as COUNT from metadata where priority_id=(select id from priority where priority=\'ERROR\') and logpath_id in (select id from logfiles where (path like \'%_compile.log\'  and path not like \'%_clean_compile.log\'))'][0]['COUNT']}</total>
        <total severity="warning">${table_info['select count(data) as COUNT from metadata where priority_id=(select id from priority where priority=\'WARNING\') and logpath_id in (select id from logfiles where (path like \'%_compile.log\'  and path not like \'%_clean_compile.log\') )'][0]['COUNT']}</total>
        <total severity="warning_rvct_other">${table_info['select count(data) as COUNT from metadata where priority_id=(select id from priority where priority=\'WARNING\') and logpath_id in (select id from logfiles where (path like \'%_compile.log\'  and path not like \'%_clean_compile.log\'))'][0]['COUNT']}</total>
        <!-- todo update to calculate the correct value -->
        <total severity="warning_rvct_bad">${table_info['select count(data) as COUNT from metadata where priority_id=(select id from priority where priority=\'REMARK\')'][0]['COUNT']}</total>
    <#list components as component>
        <component>
            <name>${component['component']}</name>
            <total severity="error">${table_info['select count(data) as COUNT from metadata where component_id =${component[\'id\']} and priority_id=(select id from priority where priority=\'ERROR\') and logpath_id in (select id from logfiles where (path like \'%_compile.log\'  and path not like \'%_clean_compile.log\'))'][0]['COUNT']}</total>
            <total severity="warning">${table_info['select count(data) as COUNT from metadata where component_id =${component[\'id\']} and priority_id=(select id from priority where priority=\'WARNING\') and logpath_id in (select id from logfiles where (path like \'%_compile.log\'  and path not like \'%_clean_compile.log\'))'][0]['COUNT']}</total>
            <total severity="critical">${table_info['select count(data) as COUNT from metadata where component_id =${component[\'id\']} and priority_id=(select id from priority where priority=\'REMARK\') and logpath_id in (select id from logfiles where (path like \'%_compile.log\'  and path not like \'%_clean_compile.log\'))'][0]['COUNT']}</total>
        </component>
    </#list>
    </faults>
    <components>
    <#list components as component>
    <!-- all components -->
        <component>${component['component']}</component>
    </#list>
    </components>
<#include "diamonds_footer.ftl"> 