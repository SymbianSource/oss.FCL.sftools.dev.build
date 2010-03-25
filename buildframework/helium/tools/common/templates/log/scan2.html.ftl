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

<#macro print_component_summary component href_c_id>
<#if component_table?keys?seq_contains("${component}")>
<#if component_table["${component}"] != "general">
<tr><td>${component_table['${component}']}</td>
<#else>
<tr><td>UnCategorized</td>
</#if>
</#if>
<#assign href_id = 0>
<#assign time_tbl = table_info['select time from componenttime where cid = \'${component}\' ']>

<#if time_tbl?size &gt; 0 && time_tbl[0]?keys?seq_contains("time") >
    <#assign time = time_tbl[0]["time"]?number/>
<#else>
    <#assign time = 0/>
</#if>

<#assign hours = (time /(60 * 60))?floor>
<#assign minutes_secs = (time % (60 * 60))?floor>
<#assign minutes = (minutes_secs / 60)?floor>
<#assign seconds = (minutes_secs % 60)?floor>

<td align="center">${hours?string("00")}:${minutes?string("00")}:${seconds?string("00")}</td>
<#list priority_ids as priority>
    <#assign count = table_info['select count(data) as COUNT from metadata where priority_id in (select id from priority      where priority like \'${priority}\') and logpath_id in (select id from logfiles where path like \'%${logfile}\') and component_id = \'${component}\' '][0]['COUNT'] >
    <#if count &gt; 0>
        <#assign color = color_list['${priority}']>
        <td align="center" bgcolor="${color}"><a href="#section${href_c_id}${href_id}">${count}</a></td>
    <#else>
        <td align="center">${count}</td>
    </#if>
    <#assign href_id = href_id + 1>
</#list>
    </tr>
</#macro>

<#macro print_list_text priority component href_id>
<#assign count = table_info['select count(data) as COUNT from metadata where component_id=\'${component}\' and priority_id in (select id from priority where priority like \'${priority}\') and logpath_id in (select id from logfiles where path like \'%${logfile}\')'][0]['COUNT'] >
<#if count &gt; 0>
<#if component_table?keys?seq_contains("${component}")>
    <#if component_table["${component}"] != "general">
        <h3><a name="section${href_id}">${component_table['${component}']}(${count})</a></h3>
    <#else>
        <h3><a name="section${href_id}">Uncategorized(${count})</a></h3>    
    </#if>
</#if>
    <#list table_info['select * from metadata where component_id=\'${component}\' and priority_id in (select id from priority where priority like \'${priority}\')'] as recordentry >
    ${logfile}:${recordentry['line_number']}>${recordentry['data']}<br />
    </#list>
</#if>
</#macro>

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
<#assign component_table = table_info['select id, component from component where logpath_id in (select id from logfiles where path like \'%${logfile}\') ORDER BY component'] >
<#assign general_id = table_info['select id from component where logpath_id in (select id from logfiles where path like \'%${logfile}\') and component like \'%general%\''] >

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
        count = table_info['select count(data) as COUNT from metadata where priority_id in (select id from priority where priority like \'${priority}\') and logpath_id in (select id from logfiles where path like \'%${logfile}\')'][0]['COUNT'] color=color_list['${priority}'] />
</#list>
</tr>
</table>

<#-- Summary for each component -->

<h1>${logfile}</h1>
<h2>By Component</h2>
    <table border="1" cellpadding="0" cellspacing="0" width="100%%">
        <tr>
            <th width="50%%">Component</th>
            <th width="9%%">Time</th>
            <th width="9%%">Errors</th>
            <th width="9%%">Warnings</th>
            <th width="9%%">Criticals</th>
            <th width="9%%">Notes</th>
            <th width="9%%">Info</th>
        </tr>
<#assign c_id = 0>
<#if general_id?size &gt; 0>
<@print_component_summary component="${general_id[0][\"id\"]}" href_c_id="${c_id}"/>
<#assign c_id = c_id + 1>
</#if>

<#assign component_ids = component_table?keys>
<#list component_ids as component>
<#if component_table["${component}"] != "general">
    <@print_component_summary component="${component}" href_c_id="${c_id}" />
</#if>

<#assign c_id = c_id + 1>
</#list>
</table>

<#-- Individual components status -->

<#assign href_pid = 0>
<#list priority_ids as p_id>
<#assign p_count = table_info['select count(data) as COUNT from metadata where priority_id in (select id from priority where priority like \'${p_id}\') and logpath_id in (select id from logfiles where path like \'%${logfile}\')'][0]['COUNT'] >
<#if p_count &gt; 0>
    <h3><a>${p_id} Details By Component</a></h3>
</#if>

<#assign href_cid = 0>
<#if general_id?size &gt; 0>
    <@print_list_text priority="${p_id}" component="${general_id[0][\"id\"]}" href_id="${href_cid}${href_pid}" /> 
    <#assign href_cid = href_cid + 1>
</#if>    
<#list component_ids as component>
    <#if component_table["${component}"] != "general">
        <@print_list_text priority="${p_id}" component="${component}" href_id="${href_cid}${href_pid}" />
    </#if>
    <#assign href_cid = href_cid + 1>
</#list>
<#assign href_pid = href_pid + 1>
</#list>
</body>
</html>
</#if>