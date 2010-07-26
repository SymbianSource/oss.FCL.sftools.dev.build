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

    <#assign targetInfo = {}>
    <#list doc.antDatabase.project.target as target>
        <#assign targetInfo = targetInfo + {target.name: target.deprecated}>
    </#list>
    <table border="0" width="100%" summary="">
        <#list targetInfo?keys?sort as name>
        <#if targetInfo[name]?length &gt; 0>
        <tr>
            <td style="white-space: nowrap">
            <font class="frameitemfont">
                <a href="target-${name}.html" title="${name}" target="classframe">${name}</a>
                <br/>
            </font>
            </td>
            <td style="white-space: nowrap">
            <#recurse targetInfo[name]>
            </td>
        </tr>
        </#if>
        </#list>
    </table>

    <br/>
    <font size="+1" class="frameheadingfont">
        <b>Deprecated properties</b>
    </font>
    <br/>

    <#assign propertyInfo = {}>
    <#list doc.antDatabase.project.property as property>
        <#assign propertyInfo = propertyInfo + {property.name: property.deprecated}>
    </#list>
    <table border="0" width="100%" summary="">
        <#list propertyInfo?keys?sort as name>
        <#if propertyInfo[name]?length &gt; 0>
        <tr>
            <td style="white-space: nowrap">
            <font class="frameitemfont">
                <a href="property-${name}.html" title="${name}" property="classframe">${name}</a>
                <br/>
            </font>
            </td>
            <td style="white-space: nowrap">
            <#recurse propertyInfo[name]>
            </td>
        </tr>
        </#if>
        </#list>
    </table>


<@helium_api_html_footer/>
