<#--
============================================================================ 
Name        : diamonds-api-metrics.xml.ftl 
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
    <#if (doc)??>
    <apis>
        <count type="sdk"><@totalNoOfRelease type="sdk"/></count>
        <count type="domain"><@totalNoOfRelease type="domain"/></count>
        <count type="internal"><@totalNoOfRelease type="internal"/></count>
        <count type="private"><@totalNoOfRelease type="private"/></count>
    <illegal-apis>
    <#list doc.api_dataset.api as illegal>
        <#if illegal.release.@category == 'private'>
            <api>${illegal.buildfiles.file.path}</api>
        </#if>
        <#if illegal.release.@category == 'internal'>
            <api>${illegal.buildfiles.file.path}</api>
        </#if>
    </#list>
    </illegal-apis>
    </apis>
    </#if>

<#if (doc)?? >
<#macro totalNoOfRelease type>
    <#assign count = 0>
<#list doc.api_dataset.api as apinode>
        <#if apinode.release.@category == '${type}'>
            <#assign count = count + 1>
        </#if>
    </#list>
${count}</#macro>
</#if>
