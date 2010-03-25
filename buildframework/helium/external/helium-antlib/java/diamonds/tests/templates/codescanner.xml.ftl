  <#--
============================================================================ 
Name        : diamonds-faults.ftl 
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
<#include "header.ftl">
  <faults>
    <#if (doc)?? >
      <#--<total severity="codescanner_error"><@totalNoOfSeverity type="error"/></total>-->
      <total severity="codescanner_warning"><@totalNoOfSeverity type="high"/></total>
    </#if>
  </faults>
<#include "footer.ftl">

<#macro totalNoOfSeverity type>
  <#assign count = 0>
<#if (doc)?? >
<#list doc["problemIndex/category/problem[@severity='${type}']/file"] as problem>
    <#list problem?split("\n") as lineNo>
        <#if lineNo?matches(".*[0-9].*")>
            <#assign count = count + 1>
        </#if>
    </#list>
</#list>
</#if>
${count}</#macro>