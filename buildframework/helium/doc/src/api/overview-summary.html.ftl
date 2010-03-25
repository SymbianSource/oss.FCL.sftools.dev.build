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

<@helium_api_header title="Helium API"/>


    <center>
        <h1>Helium API</h1>
    </center>
    
    <p>
    This is the API specification for the Helium build toolkit.
    </p>
    
    <ul>
        <li><a href="#packages">Packages</a></li>
        <li><a href="#projects">Projects</a></li>
    </ul>
    
    <h2><a name="packages">Packages</a></h2>
    <p>
    Helium Ant project files are grouped into packages of related functionality.
    </p>
    <table class="docutils">
        <tr>
            <th class="head">Package</th>
            <th class="head">Projects</th>
            <th class="head">Description</th>
        </tr>
        <#assign packageInfo = {}>
        <#list doc.antDatabase.package as package>
            <#assign packageInfo = packageInfo + {package.name: package}>
        </#list>
        <#list packageInfo?keys?sort as name>
            <tr>
                <td valign="top"><a href="package-${name}.html" target="classframe">${name}</a></td>
                <td>
                    <#assign projectInfo = {}>
                    <#list packageInfo[name].projectRef as projectRef>
                        <#assign projectInfo = projectInfo + {projectRef.name: doc["antDatabase/project[name='${projectRef.name}']"].summary}>
                    </#list>
                    <#list projectInfo?keys?sort as name>
                        <a href="project-${name}.html" project="classframe">${name}</a><br/>
                    </#list>
                </td>
                <td><#recurse packageInfo[name].summary></td>
            </tr>
        </#list>
    </table>
    <br/>
    
    <#--<h2><a name="projects">Projects</a></h2>
    <p>
    Helium is configured into a set of Ant project files that group related functionality.
    </p>
    <table class="docutils">
        <tr>
            <th class="head">Project name</th>
            <th class="head">Description</th>
        </tr>
        <#assign projectInfo = {}>
        <#list doc.antDatabase.project as project>
            <#assign projectInfo = projectInfo + {project.name: project}>
        </#list>
        <#list projectInfo?keys?sort as name>
            <tr>
                <td><a href="project-${name}.html" target="classframe">${name}</a></td>
                <td><#recurse projectInfo[name]></td>
            </tr>
        </#list>
    </table>
    <br/>-->

<@helium_api_html_footer/>


