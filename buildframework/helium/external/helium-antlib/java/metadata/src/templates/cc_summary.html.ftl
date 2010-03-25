<#--
============================================================================ 
Name        : cc_summary.html.ftl 
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
 
<h1>${ant['build.id']}</h1>

<#if ant?keys?seq_contains('publish')>
    <#if ant?keys?seq_contains('publish.dir.list')>
        <h2>Publish locations</h2>
        <p>
        <#list ant['publish.dir.list']?split(',') as site>
          <a href="${site}">${site}</a></br>
        </#list>
        </p>
    <#else>
        <#if ant?keys?seq_contains('publish.dir')>
        <h2>Publish locations</h2>
        <p><a href="${ant['publish.dir']}">${ant['publish.dir']}</a></p>
        </#if>
    </#if>
</#if>

<#assign ccm_logpath_table = table_info['select * from logfiles where path like \'%_ccm_get_input.log%\''] >

<#assign logpath_id = ccm_logpath_table?keys>
<#list logpath_id as logpath>
<#assign metadata_ccm_records = table_info['select * from metadata where logpath_id = ${logpath} and (priority_id = (select id from priority where priority=\'ERROR\')  or priority_id = (select id from priority where priority=\'WARNING\'))'] >
<h2>Synergy errors</h2>
    <p>
    <#list metadata_ccm_records as recordentry>
        ${recordentry['data']}
    </#list>
    </p>
</#list>

<h2>Build errors</h2>
<#assign compile_logpath_table = table_info['select * from logfiles where (path like \'%_compile.log\'  and path not like \'%_clean_compile.log\')'] >
<#assign colors = {'error': 'FF0000', 'critical': 'FF7000', 'warning': 'FFF000', 'remark': '0000FF'}/>

<table border="1" cellpadding="0" cellspacing="0" width="100%">
<tr>
    <th width="55%">Component</th>
    <th width="15%">Errors</th>
    <th width="15%">Criticals</th>
    <th width="15%">Warnings</th>
    <th width="15%">Notes</th>
</tr>
<#assign logpath_id = compile_logpath_table?keys>
<#list logpath_id as logpath>
    <#assign component_table = table_info['select id, component from component where logPath_id=${logpath}'] >
    <#assign component_ids = component_table?keys?sort >

<#list component_ids as component_id>
<tr>
<td>"${component_table['${component_id}']}"</td>
    <#list colors?keys as type>
        <#assign count = "${table_info['select count(data) as COUNT from metadata where logpath_id=${logpath} and (priority_id = (select id from priority where priority like \"${type}\"))'][0]['COUNT']}" >
        <#if ( count?number &gt; 0)>
<td align="center" bgcolor="#${colors[type]}">${count}</td>
        <#else>
<td align="center">0</td>
        </#if>
    </#list>
</tr>
</#list>
</#list>
</table>

<#assign rom_logpath_table = table_info['select * from logfiles where (path like \'%roms.log\')'] >
<#assign logpath_id = rom_logpath_table?keys>
<#list logpath_id as logpath>
    <#assign romlog_table = table_info['select * from metadata where logpath_id = ${logpath}'] >
    <h2>ROMs ${rom_logpath_table['${logpath}']}</h2>
        <p>
    <#list romlog_table as recordentry>
        ${recordentry['data']}<br/>
    </#list>
        </p>
</#list>

<#assign policy_logpath_table = table_info['select * from logfiles where (path like \'%validate_policy.xml\')'] >
<#assign logpath_id = policy_logpath_table?keys>
<#list logpath_id as logpath>
    <#assign policy_table = table_info['select * from metadata where logpath_id = ${logpath}'] >
        <h2>Distribution Policy validation</h2>
        <p>
        <#list policy_table as recordentry>
            ${recordentry['data']}<br/>
        </#list>
        </p>
</#list>

<#if ant?keys?seq_contains('diamonds.build.id')>
<p>
<h2>ATS Test Results</h2>
    <a href="http://${ant['diamonds.host']}${ant['diamonds.build.id']}#tab=4" >http://${ant['diamonds.host']}${ant['diamonds.build.id']}#tab=4 </a>
</p>
</#if>