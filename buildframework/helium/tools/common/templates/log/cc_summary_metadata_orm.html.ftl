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
<h2>Synergy errors</h2>
    <p>
    <#list table_info['native:com.nokia.helium.jpa.entity.metadata.MetadataEntry']['select * from metadataentry m INNER JOIN priority p ON p.priority_id=m.priority_id where m.logpath_id=${logfile.id} and ( UPPER(p.priority) like \'ERROR\' or UPPER(p.priority) like \'WARNING\' )'] as entry >
        ${entry.text}<br/>
    </#list>
    </p>
</#list>

<#list table_info['jpa']['select l from LogFile l where LOWER(l.path) like \'%_compile.log\' and LOWER(l.path) not like \'%_clean_%compile.log\''] as logfile>
<h2>Build errors (${logfile.path})</h2>
<#assign colors = {'error': 'FF0000', 'critical': 'FF7000', 'warning': 'FFF000', 'remark': '0000FF'}/>

<table border="1" cellpadding="0" cellspacing="0" width="100%">
<tr>
    <th width="55%">Component</th>
    <th width="15%">Errors</th>
    <th width="15%">Criticals</th>
    <th width="15%">Warnings</th>
    <th width="15%">Notes</th>
</tr>

<#list table_info['jpa']['select c from Component c where c.logPathID=${logfile.id} ORDER BY c.component'] as component>
<tr>
<td>${component.component}</td>
    <#list colors?keys as type>
        <#assign count =  table_info['jpasingle']['select count(m.id) from MetadataEntry m JOIN  m.priority as p JOIN m.component as c where (UPPER(p.priority)=\'${type?upper_case}\' and c.id=${component.id})'][0] >    
        <#if type=='error'>
            <#assign count_missing = table_info['jpasingle']['select count(w.id) from WhatLogEntry w JOIN w.component c where c.logPathID=${logfile.id} and c.id=${component.id} and w.missing=\'true\''][0]> 
            <#assign count = count?number + count_missing?number>
        </#if>
        <#if (count?number > 0)>
<td align="center" bgcolor="#${colors[type]}">${count}</td>
        <#else>
<td align="center">0</td>
        </#if>
    </#list>
</tr>
</#list>
</table>
</#list>

<#list table_info['jpa']['select l from LogFile l where LOWER(l.path) like \'%roms.log\''] as logfile>
    <h2>ROMs ${logfile.path}</h2>
        <p>
    <#list table_info['native:com.nokia.helium.jpa.entity.metadata.MetadataEntry']['select * from metadataentry m where m.logpath_id=${logfile.id}'] as entry >
        ${entry.text}<br/>
    </#list>
        </p>
</#list>

<#list table_info['jpa']['select l from LogFile l where LOWER(l.path) like \'%validate-policy.summary.xml\''] as logfile>
<h2>Distribution Policy validation</h2>
        <p>
        <#list table_info['native:com.nokia.helium.jpa.entity.metadata.MetadataEntry']['select * from metadataentry m where m.logpath_id=${logfile.id}'] as entry >
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