<#--
============================================================================ 
Name        : validate-policy.log.ftl 
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
CSV validation:
<#list doc["./policyvalidation/error[@type='unknownstatus']"] as unknownstatus>
    ${unknownstatus.@message} (${unknownstatus.@value})
</#list>

Errors:
<#list doc["./policyvalidation/error"] as error>
    <#if error.@type=='A' || error.@type=='B' || error.@type=='C' || error.@type=='D'>
    ${error.@type}  Found incorrect for ${error.@message?replace('([\\\\/][^\\\\/]+?)$', '', 'ris')}, ${error.@value}
    </#if>
</#list>

Missing policy files in:
<#list doc["./policyvalidation/error[@type='missing']"] as missing>
    ${missing.@message}
</#list>


Incorrect policy files in:
<#list doc["./policyvalidation/error[@type='invalidencoding']"] as error>
    ${error.@message}
</#list>
