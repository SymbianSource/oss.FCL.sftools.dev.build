<#--
============================================================================ 
Name        : validate-policy-log.xml.ftl 
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
<quality aspect="policy">
    <#if (doc)??!""?keys?seq_contains('policyvalidation')>
    <summary message="Policy validation errors" value="${doc['policyvalidation'].error?size}"/>
    <#list doc['policyvalidation'].error as error>
    <message severity="error" type="${error.@type}" message="${error.@message}" value="${error.@value}"/>
    </#list>
    </#if>
</quality>
<#include "diamonds_footer.ftl">
