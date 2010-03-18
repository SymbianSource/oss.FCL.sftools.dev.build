<#--
============================================================================ 
Name        : coverity.summary.xml.ftl 
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
<coverity>
    <#assign htmlString = covsummary?replace("["," ")>
    <#assign htmlString = htmlString?replace("]"," ")>
    <#list htmlString?split(",") as line>
        <#if !line?contains("cov-analyze") && !line?starts_with("---") && !line?contains("summary") && !line?contains("defects") >
            <#assign words = line?split(":")>
            <#if words[1]??>
                <#assign firstword=words[0]?trim secondword=words[1]?trim>
<summary message="${firstword}" value="${secondword}"/> 
            </#if>
        </#if>
    </#list>
</coverity>
        
