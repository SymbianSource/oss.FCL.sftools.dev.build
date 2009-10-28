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

<#if (doc["/logSummary/log[contains(@filename,'_ccm_get_input.log')]"]?size > 0)>
<h2>Synergy errors</h2>
    <p>
    <#list doc["/logSummary/log[contains(@filename,'_ccm_get_input.log')]//message"] as msg>
        <#if msg.@priority?matches('error|warning') >${msg}<br/></#if>
    </#list>
    </p>
</#if>

<h2>Build errors</h2>
<#assign components = pp.newWritableHash()/>
<#assign colors = {'error': 'FF0000', 'critical': 'FF7000', 'warning': 'FFF000', 'note': '0000FF'}/>
<#list doc["/logSummary/log[@filename]"] as log>
    <#if log.@filename?matches(".*_compile.log$") && !log.@filename?matches(".*(?:_ant|_clean)_compile.log$")>
        <#list log[".//task"] as task>
            <#assign name = task.@name/>
            <#if !components?keys?seq_contains(name)>
                <@pp.set hash=components key="${name}" value=pp.newWritableHash() />
            </#if>
            <#list task["./message"] as msg>
                <#if components[name]?keys?seq_contains(msg.@priority)>
                    <@pp.set hash=components[name] key=msg.@priority value=1+components[name][msg.@priority] />
                <#else>
                    <@pp.set hash=components[name] key=msg.@priority value=1 />
                </#if>
            </#list>
        </#list>
    </#if>
</#list>

<table border="1" cellpadding="0" cellspacing="0" width="100%">
<tr>
    <th width="55%">Component</th>
    <th width="15%">Errors</th>
    <th width="15%">Criticals</th>
    <th width="15%">Warnings</th>
    <th width="15%">Notes</th>
</tr>
<#list components?keys as component>
<tr>
<td>${component}</td>
    <#list colors?keys as type>
        <#if components[component]?keys?seq_contains(type)>
<td align="center" bgcolor="#${colors[type]}">${components[component][type]}</td>
        <#else>
<td align="center">0</td>
        </#if>
    </#list>
</tr>
</#list>
</table>

<#list doc["/logSummary/log[@filename]"] as log>
    <#if log.@filename?matches(".*roms.log$")>
    <h2>ROMs (${log.@filename})</h2>
        <p>
        <#list log[".//message"] as message>
            ${message}<br/>
        </#list>    
        </p>    
    </#if>
</#list>

<#list doc["/logSummary/log[@filename]"] as log>
    <#if log.@filename?matches(".*_validate_policy\\....$")>
        <h2>Distribution Policy validation</h2>
        <p>
        <#list log[".//message"] as msg>
        ${msg}<br/>
        </#list>
        </p>
    </#if>
</#list>

<#if ant?keys?seq_contains('diamonds.build.id')>
<p>
<h2>ATS Test Results</h2>
    <a href="http://${ant['diamonds.host']}${ant['diamonds.build.id']}#tab=4" >http://${ant['diamonds.host']}${ant['diamonds.build.id']}#tab=4 </a>
</p>
</#if>