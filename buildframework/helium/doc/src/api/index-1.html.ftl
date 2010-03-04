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

<@helium_api_header title="Index (Helium API)"/>



    <h1>Index</h1>
    <dl>
        <#assign indexlist = {}>
        <#list doc.antDatabase.project.property.name as propertyName>
            <#assign indexlist = indexlist + {propertyName: "property"}>
        </#list>
        <#list doc.antDatabase.project.target.name as targetName>
            <#assign indexlist = indexlist + {targetName: "target"}>
        </#list>
        
        <#assign alphabetlist = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']>
        <#list alphabetlist as letter>
            <a href="#${letter}">${letter?upper_case}</a>
        </#list>
        
        <#list alphabetlist as letter>
            <h2><a name="${letter}">${letter?upper_case}</a></h2>
            <#list indexlist?keys?sort as element>
                <#if element?starts_with(letter)>
                    <dt><a href="${indexlist[element]}-${element}.html">${element}</a></dt>
                </#if>
            </#list>
            <p/>
        </#list>
    </dl>


<@helium_api_html_footer/>
