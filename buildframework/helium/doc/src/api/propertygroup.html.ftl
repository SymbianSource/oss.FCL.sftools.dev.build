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

<#list doc.antDatabase.project.group as group>
<@pp.changeOutputFile name="propertygroup-${group.name}.html" />

<@helium_api_header title="Property group ${group.name}"/>



<h2>Property group ${group.name}</h2>

<h3>Description </h3>
<p>
${group.description}
</p>

<h3>Properties</h3>
<#assign propertyList=group.propertyRef?sort>
<p> 
<table class="docutils" width="50%">
    <tr>
        <th class="head">Name</th>
        <th class="head">Edit status</th>
        <th class="head">Deprecated</th>
    </tr>
    <tr>
        <td colspan="3">User editable properties</td>
    </tr>
    <#list propertyList as property>
        <#list doc.antDatabase.project.property as propDataModel>
            <#if property == propDataModel.name>
                <#if propDataModel.editable == "must" || propDataModel.editable == "recommended" || propDataModel.editable == "allowed">
                    <tr>
                        <td><a href="property-${property}.html" title="${propDataModel.description}" target="classframe"><tt class="docutils literal">${property}</tt></a></td>
                        <td><a href="help.html" title="Help" target="classframe">${propDataModel.editable}</a></td>
                        <td>
                            <#if propDataModel.deprecated?size &gt; 0>
                                ${propDataModel.deprecated}
                            </#if>
                        </td>
                    </tr>
                </#if>
            </#if>
        </#list>
    </#list>
    <tr>
        <td colspan="3">Internal properties</td>
    </tr>
    <#list propertyList as property>
        <#list doc.antDatabase.project.property as propDataModel>
            <#if property == propDataModel.name>
                <#if propDataModel.editable == "never" || propDataModel.editable == "discouraged">
                    <tr>
                        <td><a href="property-${property}.html" title="${propDataModel.description}" target="classframe"><tt class="docutils literal">${property}</tt></a></td>
                        <td><a href="help.html" title="Help" target="classframe">${propDataModel.editable}</a></td>
                        <td>
                            <#if propDataModel.deprecated?size &gt; 0>
                                ${propDataModel.deprecated}
                            </#if>
                        </td>
                    </tr>
                </#if>
            </#if>
        </#list>
    </#list>
</table>
</p>



<@helium_api_html_footer/>

</#list>


