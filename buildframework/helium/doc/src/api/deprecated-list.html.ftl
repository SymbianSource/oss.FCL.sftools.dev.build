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

<@helium_api_header title="Deprecated targets (Helium)"/>


    <font size="+1" class="frameheadingfont">
        <b>Deprecated targets</b>
    </font>
    <br/>

    <table border="0" width="100%" summary="">
    <tr>
    <td style="white-space: nowrap">
    <#assign targetlist=doc.antDatabase.project.target.name?sort>
    <#list targetlist as targetvar>
    
      <#list doc.antDatabase.project.target as targetref>
        <#if targetvar == targetref.name>
          <#if targetref.deprecated?size &gt; 0>
          <font class="frameitemfont">
              <a href="target-${targetvar}.html" title="${targetvar}" target="classframe">${targetvar}</a>
              <br/>${targetref.deprecated}
          </font>
          <br/>
          </#if>
        </#if>
      </#list>
    
    </#list>
    </td>
    </tr>
    </table>

    <br/>
    <font size="+1" class="frameheadingfont">
        <b>Deprecated properties</b>
    </font>
    <br/>

    <table border="0" width="100%" summary="">
    <tr>
    <td style="white-space: nowrap">
    <#assign propertylist=data.heliumDataModel.property.name?sort>
    <#list propertylist as propertyvar>
      <#list data.heliumDataModel.property as propertyref>
      <#if propertyvar == propertyref.name>
        <#if propertyref.deprecated?size &gt; 0>
        <font class="frameitemfont">
        <a href="property-${propertyvar}.html" title="${propertyvar}" target="classframe">${propertyvar}</a>
        <br/>${propertyref.deprecated}
        </font>
        <br/>
        </#if>
      </#if>
      </#list>
    </#list>
    </td>
    </tr>
    </table>


<@helium_api_html_footer/>
