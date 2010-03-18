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

<@helium_api_header title="Properties (Helium API)"/>

<script type="text/javascript" src="properties-table.js"></script>

    <#assign propertyInfo = {}>
    <#list doc.antDatabase.project.property as property>
        <#assign propertyInfo = propertyInfo + {property.name: property}>
    </#list>
        
    <center>
    <h1>Properties table(Sortable)
    </h1>
    
    <table class="sortable" border="1" cellpadding="5" ID="tableSort">
        <tr>
            <th onmouseover="this.style.cursor = 'pointer';"><font color="blue"><u>Property</u></font></th>
            <th onmouseover="this.style.cursor = 'pointer';"><font color="blue"><u>Description</u></font></th>
            <th onmouseover="this.style.cursor = 'pointer';"><font color="blue"><u>Scope</u></font></th>
            <th onmouseover="this.style.cursor = 'pointer';"><font color="blue"><u>Editable</u></font></th>
            <th onmouseover="this.style.cursor = 'pointer';"><font color="blue"><u>Type</u></font></th>
        </tr>
        <#list propertyInfo?keys?sort as name>
        <tr>
            <td><a href="property-${name}.html" title="${name}" target="classframe">${name}</a></td>
            <td>${propertyInfo[name].summary}</td>
            <td>${propertyInfo[name].scope}</td>
            <td>${propertyInfo[name].editable}</td>
            <td>${propertyInfo[name].type}</td>
        </tr>
        </#list>
    </table>


<@helium_api_html_footer/>



