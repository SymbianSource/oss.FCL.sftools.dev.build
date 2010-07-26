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

<#list doc.antDatabase.project.property as property>
<@pp.changeOutputFile name="property-${property.name}.html" />

<@helium_api_header title="property ${property.name}"/>


    
<h2>Property ${property.name}</h2>

<b>Type: </b>${property.type}<br/>
<b>Scope: </b>${property.scope}<br/>
<b>Editable: </b>${property.editable}<br/>

<b>Default value: </b>
<#assign defaultValue = "Not defined">
<#if property.defaultValue?size &gt; 0>
    <#assign defaultValue = property.defaultValue>
</#if>      
<tt class="docutils literal">${defaultValue}</tt>
<br/>

<#if property.deprecated?length &gt; 0>
    <b>Deprecated</b>
    <p>
    ${property.deprecated}
    </p>        
</#if>

<hr/>

<h3>Documentation</h3>
<p>
${property.documentation}
</p>

<hr/>

<h3>Source code</h3>
<pre>
    ${property.source?html}
</pre>



<@helium_api_html_footer/>

</#list>


