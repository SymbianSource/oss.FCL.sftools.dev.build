<#--
============================================================================ 
Name        : bmd.macros.xml.ftl 
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

<#macro add_severity_count severity, color, count>
    <#if count &gt; 0>
        <#if severity == 'error'>
<td width="12%%" align="center" bgcolor="${color}">${count}</td>
        <#else>
<td align="center" bgcolor="${color}">${count}</td>
        </#if>
    <#else>
    <td align="center">${count}</td>
    </#if>
</#macro>
<#if (doc)??>
    <#assign logfile = "${doc.sbsinfo.logfile.@name}" >
    <#assign time = "${doc.sbsinfo.duration.@time}" >

    <#assign table_info = pp.loadData('com.nokia.helium.metadata.SQLFMPPLoader',
        "${dbPath}") >
<#-- overall summary -->
<#assign component_table = table_info['select id, component from component where logpath_id in (select id from logfiles where path like \'%${logfile}%\')'] >
<html>
<head><title>${logfile}</title></head>
<body>
<h2>Overall</h2>
<table border="1" cellpadding="0" cellspacing="0" width="100%%">
<tr>
    <th width="22%%">&nbsp;</th>
    <th width="11%%">Time</th>
    <th width="11%%">Errors</th>
    <th width="11%%">Warnings</th>
    <th width="11%%">Critical</th>
    <th width="23%%">Migration Notes</th>
    <th width="11%%">Info</th>
</tr>
<tr>
<td width="22%%">Total</td>
<td width="12%%" align="center">${time}</td>
<#assign color_list={'error': 'FF0000', 'warning': 'FFF000', 'critical': 'FF7000', 'remark': '0000FF', 'info': 'FFFFFF'}>
<#assign priority_ids = color_list?keys>
<#list priority_ids as priority>
    <@add_severity_count severity='${priority}' 
        count = table_info['select count(data) as COUNT from metadata where priority_id in (select id from priority where priority like \'${priority}\') and logpath_id in (select id from logfiles where path like \'%${logfile}%\')'][0]['COUNT'] color=color_list['${priority}'] />
</#list>
</tr>
</table>

<#-- Summary for each component -->

<h1>${logfile}</h1>
<h2>By Component</h2>
    <table border="1" cellpadding="0" cellspacing="0" width="100%%">
        <tr>
            <th width="50%%">Component</th>
            <th width="10%%">Errors</th>
            <th width="10%%">Warnings</th>
            <th width="10%%">Criticals</th>
            <th width="10%%">Notes</th>
            <th width="10%%">Info</th>
        </tr>
<#assign component_ids = component_table?keys>
<#assign href_id = 0>
<#list component_ids as component>
<tr><td>${component_table['${component}']}</td>
<#list priority_ids as priority>
    <#assign count = table_info['select count(data) as COUNT from metadata where priority_id in (select id from priority      where priority like \'${priority}\') and logpath_id in (select id from logfiles where path like \'%${logfile}%\') and component_id = \'${component}\' '][0]['COUNT'] >
    <#if count &gt; 0>
        <td align="center" bgcolor="${color_list['${priority}']}"><a href="#section${href_id}">${count}</a></td>
        <#assign href_id = href_id + 1>
    <#else>
        <td align="center">${count}</td>
    </#if>
</#list>
</tr>
</#list>
</table>

<#-- Individual components status -->

<#assign component_ids = component_table?keys>
<#assign href_id = 0>
<#list component_ids as component>
<#assign displayComponentHeader= 0 >
<#list priority_ids as priority>
<#assign displayPriorityHeader= 0 >
<#assign count = table_info['select count(data) as COUNT from metadata where component_id=\'${component}\' and priority_id in (select id from priority where priority like \'${priority}\')'][0]['COUNT'] >
<#if count &gt; 0>
    <h3><a name="section${href_id}">${priority} for ${component_table['${component}']}</a></h3>
    <#assign href_id = href_id + 1>
    <table border="1" cellpadding="0" cellspacing="0" width="100%%">
    <tr>
        <th width="85%%">Text</th>
        <th width="15%%">Line Number</th>
    </tr>
    <#list table_info['select * from metadata where component_id=\'${component}\' and priority_id in (select id from priority where priority like \'${priority}\')'] as recordentry >
    <tr><td>${recordentry['data']}</td><td>${recordentry['line_number']}</td></tr>
    </#list>
    </table>
</#if>
</#list>
</#list>
</body>
</html>
</#if>