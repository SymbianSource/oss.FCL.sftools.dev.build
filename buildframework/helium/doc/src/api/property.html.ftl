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

<#list data.heliumDataModel.property as property>
<@pp.changeOutputFile name="property-${property.name}.html" />

<@helium_api_header title="property ${property.name}"/>


    
<h2>Property ${property.name}</h2>
<b>Type</b>
<p>
${property.type}
</p>
<b>Edit status</b>
<p>
${property.editStatus}
</p>
<b>Default value</b>
<#assign ifDefined = false>
<#list doc.antDatabase.project.property as propDatabase>
    <#if propDatabase.name == property.name>       
        <p>
        <tt class="docutils literal">${propDatabase.defaultValue}</tt>
        </p>
        <#assign ifDefined = true>
        <#break>
    </#if>
</#list>
<#if ifDefined == false>
    <p>
    None defined.
    </p>
</#if>
<#if property.deprecated?size &gt; 0>
    <b>Deprecated</b>
    <p>
    ${property.deprecated}
    </p>        
</#if>

<hr/>

<h3>Description</h3>
<p>
${property.description}
</p>



<@helium_api_html_footer/>

</#list>


