  <#--
============================================================================ 
Name        : coverity.xml.ftl 
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
<#include "diamonds_header.ftl">
    <quality aspect="coverity"> 
        <#if (doc)?? >
            <#list doc["coverity/coverity/summary"] as summary>
                <summary message="${summary.@message}" value="${summary.@value}"/> 
            </#list>
        </#if>
        <#if (doc)?? >
            <#list doc["coverity/error"] as error>
                <#if error.checker?contains("Total")>
                <summary message="Total Errors" value="${error.num}"/>
                </#if>
            </#list>
        </#if>
        <#if (doc)?? >
            <#list doc["coverity/error"] as error>
                <#if !error.checker?contains("Total")>
                <message severity="error" type="${error.checker}" message="Checker name" location=" " value="${error.num}"/> 
                </#if>
            </#list>
        </#if>
    </quality>
<#include "diamonds_footer.ftl">
