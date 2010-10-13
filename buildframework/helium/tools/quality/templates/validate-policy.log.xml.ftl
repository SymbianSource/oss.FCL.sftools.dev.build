<#--
============================================================================ 
Name        : validate-policy.log.xml.ftl 
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
<?xml version="1.0" encoding="utf-8"?>
<log filename="${ant['validate.policy.log']}">
    <build>
        <task name="CSV validation">
<#list doc["./policyvalidation/error[@type='unknownstatus']"] as unknownstatus>
            <message priority="error"><![CDATA[${unknownstatus.@message} (${unknownstatus.@value})]]></message>
</#list>
        </task>
        <task name="Issues">
<#list doc["./policyvalidation/error"] as error>
    <#if error.@type=='A' || error.@type=='B' || error.@type=='C' || error.@type=='D'>
            <message priority="error"><![CDATA[${error.@type}  Found incorrect for ${error.@message?replace('([\\\\/][^\\\\/]+?)$', '', 'ris')}, ${error.@value}]]></message>
    </#if>
</#list>
        </task>
        <task name="Missing">
Missing policy files in:
<#list doc["./policyvalidation/error[@type='missing']"] as missing>
            <message priority="error"><![CDATA[${missing.@message}]]></message>
</#list>
        </task>
        <task name="Incorrect policy files">
<#list doc["./policyvalidation/error[@type='invalidencoding']"] as error>
            <message priority="error"><![CDATA[${error.@message}]]></message>
</#list>
        </task>
    </build>
</log>
