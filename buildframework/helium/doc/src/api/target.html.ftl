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

<#list doc.antDatabase.project.target as target>
<@pp.changeOutputFile name="target-${target.name}.html" />

<@helium_api_header title="Target ${target.name}"/>


    
<h2>Target ${target.name}</h2>

<p><b>Location</b></p>
<p><@helium_api_location_path location="${target.location}"/></p>

<p><b>Conditional execution</b></p>        
<#if target.ifDependency?length &gt; 0>
<p>Target <b>is</b> run if property defined: <code>${target.ifDependency}</code></p>
</#if>
<#if target.unlessDependency?length &gt; 0>
<p>Target <b>is not</b> run if property defined: <code>${target.unlessDependency}</code></p>
</#if>
<#if target.ifDependency?length == 0 && target.unlessDependency?length == 0>
<p>No conditions on target execution.</p>
</#if>
<hr/>

<h3>Description</h3>
<p>
<#recurse target.documentation>
</p>
<p/>
<hr/>


<#assign executableList=target.executable?sort>
<#if executableList?size &gt; 0>
<h3>Target external Dependency</h3>
<p> 
<table class="docutils" width="50%">
    <tr>
        <th class="head">Name</th>
    </tr>
    <#list executableList as excutable>
        <tr>
                    <td>${excutable}</td>
            </tr>
    </#list>
</table>
</p>
</#if>


<h3>Property dependencies</h3>

<#assign propertyList=target.propertyDependency?sort>

<p> 
<table class="docutils" width="50%">
    <tr>
        <th class="head">Name</th><th class="head">Edit status</th>
    </tr>
    <tr>
        <td colspan="2">User editable properties</td>
    </tr>
    <#list propertyList as property>
        <#list data.heliumDataModel.property as propDataModel>
            <#if property == propDataModel.name>
                <#if propDataModel.editStatus == "must" || propDataModel.editStatus == "recommended" || propDataModel.editStatus == "allowed">
                    <tr>
                        <td><a href="property-${property}.html" title="${propDataModel.description}" target="classframe"><tt class="docutils literal">${property}</tt></a></td><td><a href="help.html" title="Help" target="classframe">${propDataModel.editStatus}</a></td>
                    </tr>
                </#if>
            </#if>
        </#list>
    </#list>
    <tr>
        <td colspan="2">Internal properties</td>
    </tr>
    <#list propertyList as property>
        <#list data.heliumDataModel.property as propDataModel>
            <#if property == propDataModel.name>
                <#if propDataModel.editStatus == "never" || propDataModel.editStatus == "discouraged">
                    <tr>
                        <td><a href="property-${property}.html" title="${propDataModel.description}" target="classframe"><tt class="docutils literal">${property}</tt></a></td><td><a href="help.html" title="Help" target="classframe">${propDataModel.editStatus}</a></td>
                    </tr>
                </#if>
            </#if>
        </#list>
    </#list>
</table>
</p>

<#if target.deprecated?size &gt; 0>
    <h3>Deprecated :</h3>
    <p>
    ${target.deprecated}
    </p>
</#if>
<hr/>


<h3>Target dependencies</h3>
<p align="center">
<img src="target-${target.name}.dot.png" alt="${target.name} dependencies" usemap="#dependencies"
     style="border-style: none"/>
<map name="dependencies" id="dependencies">
  <#attempt>
      <#include "target-${target.name}.dot.cmap"/>
      <#recover>
  </#attempt>
</map>
</p>
<hr/>


<h3>Source code</h3>
<pre>
    ${target.source?html}
</pre>


<@helium_api_html_footer/>

</#list>


