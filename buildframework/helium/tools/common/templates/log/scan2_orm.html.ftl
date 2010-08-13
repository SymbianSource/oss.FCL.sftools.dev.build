<#--
============================================================================ 
Name        : scan2_orm.html.ftl 
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

<#macro print_component_summary component href_c_id >
<#assign href_id = 0>
<#assign component_time_list = table_info['jpasingle']['select t.componentTime from ComponentTime t where  t.componentId =${component.id}']>

<#if component_time_list[0]?? >
    <#assign time = component_time_list[0]?number>
<#else>
    <#assign time = 0>
</#if>
<tr>
<#assign hours = (time /(60 * 60))?floor>
<#assign minutes_secs = (time % (60 * 60))?floor>
<#assign minutes = (minutes_secs / 60)?floor>
<#assign seconds = (minutes_secs % 60)?floor>
    <td>${component.component}</td>
<#--write each of the component tables information -->
<td align="center">${hours?string?left_pad(2, "0")}:${minutes?string?left_pad(2, "0")}:${seconds?string?left_pad(2, "0")}</td>
<#list color_list?keys as severity>
    <#assign count =  table_info['jpasingle']['select count(m.id) from MetadataEntry as m JOIN  m.severity as p JOIN m.component as c where p.severity=\'${severity?upper_case}\' and c.id=${component.id}'][0] >
    <#if count &gt; 0>
        <#assign color = color_list['${severity}']>
        <td align="center" bgcolor="${color}"><a href="#section${severity}${href_c_id}">${count}</a></td>
    <#else>
        <td align="center">${count}</td>
    </#if>
    <#assign href_id = href_id + 1>
</#list>
</tr>
</#macro>

<#macro converttime time>${((time/3660)%60)?string?left_pad(2, "0")}:${((time/60)%60)?string?left_pad(2, "0")}:${(time%60)?string?left_pad(2, "0")}</#macro>

<#macro print_list_text severity component href_id>
<#assign count =  table_info['jpasingle']['select count(m.id) from MetadataEntry as m JOIN m.severity as p JOIN m.component as c where p.severity=\'${severity?upper_case}\' and c.id=${component.id}'][0] >
<#if count?? && count?number &gt; 0>
<#if "${component.component}" != "general">
        <h3><a name="section${href_id}">${component.component}(${count})</a></h3>
    <#else>
        <h3><a name="section${href_id}">Uncategorized(${count})</a></h3>
    </#if>
<#list table_info['jpa']['select e from MetadataEntry e JOIN e.severity s where e.componentId=${component.id} and s.severity=\'${severity?upper_case}\''] as entry>
${logfile.path}:${entry.lineNumber}>${entry.text}<br />
</#list>
</#if>
</#macro>

<#macro component_check_error component count >
</#macro>

<#macro add_severity_count severity, color, count>
    <#if count &gt; 0>
<td width="12%%" align="center" bgcolor="${color}"><a href="#${severity}">${count}</a></td>
    <#else>
    <td align="center">${count}</td>
    </#if>
</#macro>

<#-- end of macros code starts here -->


<#if (logfilename)??>
    <#assign logfilename_cleaned = "${logfilename}"?replace("\\","/") >
    <#assign table_info = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader',
        "${dbPath}") >
<#-- overall summary -->
<#assign logfile = table_info['jpasingle']['select l from LogFile l where LOWER(l.path)=\'${logfilename_cleaned?lower_case}\''][0] >
<#assign time = table_info['jpasingle']['select et from ExecutionTime et where et.logFileId=${logfile.id}'][0] >
<html>
<head><title>${logfile.path}</title></head>
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
<#-- need to create variables for the items to be displayed in the comment title Overall_Total
doing this the long winded way because I could not find a way to add items to a hash in a loop -->
<#assign color_list={'error': 'FF0000', 'warning': 'FFF000', 'critical': 'FF7000', 'remark': 'FFCCFF', 'info': 'FFFFFF'}>
<#assign severity_ids = color_list?keys>
<td width="22%%">Total</td>
<td width="12%%" align="center"><@converttime time=time.time /></td>
<#assign count_check_errors = table_info['jpasingle']['select Count(w.id) from WhatLogEntry w JOIN w.component c where c.logFileId=${logfile.id} and w.missing=\'true\''][0]> 
<#list severity_ids as severity>
    <#assign count = table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.severity p where m.logFileId=${logfile.id} and p.severity=\'${severity?upper_case}\''][0]>
    <#if  '${severity}' == 'error'  && !logfile.path?contains('_clean_')>
        <#assign count = count>
    </#if>
    <@add_severity_count severity='${severity}' color=color_list['${severity}'] 
        count = count />
</#list>
</tr>
</table>

<#-- Summary for each component -->

<h1>${logfile.path}</h1>
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
<#assign general_component_list = table_info['jpasingle']['select c from Component c where LOWER(c.component) like \'%general%\' and c.logFileId=${logfile.id}']>
<#if general_component_list[0]?? >
<#assign general_component = general_component_list[0] >
<@print_component_summary component=general_component  href_c_id="${c_id}"/>
<#assign c_id = c_id + 1>
</#if>
<#list table_info['jpa']['select c from Component c where c.logFileId=${logfile.id} and LOWER(c.component) not like \'%general%\' ORDER BY c.component'] as componentEntry>
<@print_component_summary component=componentEntry href_c_id="${c_id}"/>
<#assign c_id = c_id + 1>

</#list>
</table>

<#-- Individual components status -->
<#list severity_ids as p_id>
<#assign p_count = table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.severity as p where m.logFileId=${logfile.id} and p.severity=\'${p_id?upper_case}\''][0]>
<#if p_count &gt; 0>
    <h3><a>${p_id} Details By Component</a></h3>
</#if>
<#assign href_cid = 0>
<#if general_component??>
    <@print_list_text severity="${p_id}" component=general_component href_id="${p_id}${href_cid}" /> 
    <#assign href_cid = href_cid + 1>
</#if>
<#list table_info['jpa']['select c from Component c where c.logFileId=${logfile.id} and LOWER(c.component) not like \'%general%\' ORDER BY c.component'] as componentEntry>
    <@print_list_text severity="${p_id}" component=componentEntry href_id="${p_id}${href_cid}" />
    <#assign href_cid = href_cid + 1>
</#list>
</#list>
</table>
</body>
</html>
</#if>