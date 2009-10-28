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
        <li><a href="#projects">Projects</a></li>
        <li><a href="#propertygroups">Property groups</a></li>
    </ul>
    
    <h2><a name="projects">Projects</a></h2>
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
            <#assign projectInfo = projectInfo + {project.name: project.documentation}>
        </#list>
        <#list projectInfo?keys?sort as name>
            <tr>
                <td><a href="project-${name}.html" target="classframe">${name}</a></td>
                <td><#recurse projectInfo[name]></td>
            </tr>
        </#list>
    </table>
    <br/>
    
    <h2><a name="propertygroups">Property groups</a></h2>
    <p>
    Property groups define a set of properties that relate to a specific feature or functionality in Helium.
    </p>
    <table class="docutils">
        <tr>
            <th class="head">Property group name</th>
            <th class="head">Description</th>
        </tr>
        <#list data.heliumDataModel.group as group>
            <tr>
                <td><a href="propertygroup-${group.name}.html" target="classframe">${group.name}</a></td>
                <td>${group.description}</td>
            </tr>
        </#list>
    </table>    

<@helium_api_html_footer/>