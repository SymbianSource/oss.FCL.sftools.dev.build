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

    <center>
    <h1>
    Properties table(Sortable)
    </h1>
    <table class="sortable" border="1" cellpadding="5" ID="tableSort">
    <tr>
    <th onmouseover="this.style.cursor = 'pointer';"><font color="blue"><u>Property</u></font></th>
    <th onmouseover="this.style.cursor = 'pointer';"><font color="blue"><u>Description</u></font></th>
    <th onmouseover="this.style.cursor = 'pointer';"><font color="blue"><u>Edit Status</u></font></th>
    <th onmouseover="this.style.cursor = 'pointer';"><font color="blue"><u>Type</u></font></th>
    </tr>
    <#assign propertySort=data.heliumDataModel.property.name?sort>
    <#assign propertyTable=data.heliumDataModel.property>
    <#list propertySort as propertyName>
    <#list propertyTable as property>
    <#if propertyName == property.name>
    <tr>
    <td><a href="property-${property.name}.html" title="${property.name}" target="classframe">${property.name}</a></td>
    <td>${property.description}</td>
    <td>${property.editStatus}</td>
    <td>${property.type}</td>
    </tr>
    </#if>
    </#list>
    </#list>
    </table>


<@helium_api_html_footer/>