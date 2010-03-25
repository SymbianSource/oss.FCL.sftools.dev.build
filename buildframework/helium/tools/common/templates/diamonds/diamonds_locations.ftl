<#--
============================================================================ 
Name        : locations.ftl 
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
<locations>
    <#if ant?keys?seq_contains("release.hydra.dir")>
        <location>
               <link>${ant["release.hydra.dir"]}</link>
               <description>Hydra server</description>
        </location>
    </#if>
    <#if ant?keys?seq_contains("publish.dir.list")>
        <#list ant["publish.dir.list"]?split(",") as path>
            <#if !path?contains("${")>
                <location>
                       <link>${path}</link>
                       <description>Shared drive</description>
                </location>
            </#if>
        </#list>
    </#if>
    <#if (ant?keys?seq_contains("publish.dir") && !ant["publish.dir"]?contains("${"))>
        <location>
            <link>${ant["publish.dir"]}</link>
            <description>Shared drive</description>
        </location>
    </#if>
</locations>
