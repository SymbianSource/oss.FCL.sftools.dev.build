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

    <#assign table_info = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader',
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

<#list table_info['jpa']['select l from LogFile l where LOWER(l.path) like \'%_ccm_get_input.log%\''] as logfile>

<#assign metadata_ccm_records = table_info['native']['select * from metadataentry where logpath_id = ${logpath} and (priority_id in (select id from priority where priority=\'ERROR\')  or priority_id in (select id from priority where priority=\'WARNING\'))'] >
<h2>Synergy errors</h2>
    <p>
    <#list table_info['native:com.nokia.helium.jpa.entity.metadata.MetadataEntry']['select * from metadataentry INNER JOIN priority ON priority.priority_id=metadataentry.priority_id where metadateentry.logpath_id=${logfile.id} and (UPPER(priority.priority) like \'ERROR\' OR UPPER(priority.priority) like \'WARNING\''] as entry >    
        ${entry.text}
    </#list>
    </p>
</#list>

<h2>Build errors</h2>
<#list table_info['jpa']['select l from LogFile l where LOWER(l.path) like \'%_compile.log\' and path not like \'%_clean_compile.log\''] as logfile>
<#assign colors = {'error': 'FF0000', 'critical': 'FF7000', 'warning': 'FFF000', 'remark': '0000FF'}/>

<table border="1" cellpadding="0" cellspacing="0" width="100%">
<tr>
    <th width="55%">Component</th>
    <th width="15%">Errors</th>
    <th width="15%">Criticals</th>
    <th width="15%">Warnings</th>
    <th width="15%">Notes</th>
</tr>
    <#assign component_table = table_info['select id, component from component where logPath_id=${logpath}'] >
    <#assign component_ids = component_table?keys?sort >

<#list table_info['jpa']['select c from Component c where c.logpathID=${logpath.id} ORDERBY component'] as component>
<tr>
<td>"${component.id}"</td>
    <#list colors?keys as type>
         <#assign count =  table_info['jpasingle']['select count(m.id) from MetadataEntry as m JOIN  m.priority as p where (UPPER(p.priority) like \'%${type?upper_case}%\' and M.componentId=${component.id}'][0] >    
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

<#list table_info['jpa']['select l from LogFile l where LOWER(l.path) like \'%roms.log\''] as logfile>
    <h2>ROMs ${logfile.path}</h2>
        <p>
    <#list table_info['native:com.nokia.helium.jpa.entity.metadata.MetadataEntry']['select * from metadataentry where m.logpathId=${logfile.id}'] as entry >
        ${entry.text}<br/>
    </#list>
        </p>
</#list>

<#list table_info['jpa']['select l from LogFile l where LOWER(l.path) like \'%validate_policy.xml\''] as logfile>
        <h2>Distribution Policy validation</h2>
        <p>
        <#list table_info['native:com.nokia.helium.jpa.entity.metadata.MetadataEntry']['select * from metadataentry where m.logpathId=${logfile.id}'] as entry >
            ${entry.text}<br/>
        </#list>
        </p>
</#list>

<#if ant?keys?seq_contains('diamonds.build.id')>
<p>
<h2>ATS Test Results</h2>
    <a href="http://${ant['diamonds.host']}${ant['diamonds.build.id']}#tab=4" >http://${ant['diamonds.host']}${ant['diamonds.build.id']}#tab=4 </a>
</p>
</#if>