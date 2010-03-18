<#--
============================================================================ 
Name        : 
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
<#include "api.ftllib"/>

<#list doc.antDatabase.package as package>
<@pp.changeOutputFile name="package-${package.name}.html" />

<@helium_api_header title="package ${package.name}"/>


<h2>package ${package.name}</h2>


<h3>Documentation</h3>
<p>
${package.documentation}
</p>


<h3>Projects</h3>
<table class="docutils">
    <tr>
        <th class="head">Project name</th>
        <th class="head">Description</th>
    </tr>
    <#assign projectInfo = {}>
    <#list package.projectRef as projectRef>
        <#assign projectInfo = projectInfo + {projectRef.name: doc["antDatabase/project[name='${projectRef.name}']"].summary}>
    </#list>
    <#list projectInfo?keys?sort as name>
        <tr>
            <td><a href="project-${name}.html" project="classframe">${name}</a></td>
            <td><#recurse projectInfo[name]></td>
        </tr>
    </#list>
</table>


<@helium_api_html_footer/>

</#list>


