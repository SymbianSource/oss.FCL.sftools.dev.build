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

<#list doc.antDatabase.project as project>
<@pp.changeOutputFile name="project-${project.name}.html" />

<@helium_api_header title="Project ${project.name}"/>


    
<h2>Project ${project.name}</h2>

<p><b>Location</b></p>
<#if (project[".//target"]?size > 0)>
<p><@helium_project_path location="${project.target[0].location}"/></p>
</#if>
<h3>Description</h3>
<p>
${project.description}
</p>
<p/>
<hr/>


<h3>Targets</h3>
<table class="docutils">
    <tr>
        <th class="head">Target name</th>
        <th class="head">Description</th>
    </tr>
    <#assign targetInfo = {}>
    <#list project.target as target>
        <#assign targetInfo = targetInfo + {target.name: target.summary}>
    </#list>
    <#list targetInfo?keys?sort as name>
        <tr>
            <td><a href="target-${name}.html" target="classframe">${name}</a></td>
            <td><#recurse targetInfo[name]></td>
        </tr>
    </#list>
</table>

<h3>Properties</h3>

<#assign propertymodel=doc.antDatabase.project.property>
<#assign propertylist=project.property>
<#list propertymodel as propertyInModel>
<#list propertylist as propertyvar>
    <#if propertyvar.name == propertyInModel.name>
        <font class="frameitemfont">
        <a href="property-${propertyvar.name}.html" title="${propertyvar.name}" target="classframe">${propertyvar.name}</a>
        </font>
        <br/>
    </#if>
</#list>
</#list>

<h3>Project dependencies</h3>
<#assign filelist = project.projectDependency>
<#list filelist as filelistvar>
<font class="frameitemfont">
${filelistvar}
</font>
<br/>
</#list>

<#--<h3>Python Modules</h3>
<#assign pymodulelist=project.pythonDependency>
<#list pymodulelist.module as pymodulevar>
  <#if pymodulevar?size &gt; 0>        
    <font class="frameitemfont">
      ${pymodulevar}
    </font>  
  </#if>
<br/>
</#list>-->
        


<@helium_api_html_footer/>

</#list>


