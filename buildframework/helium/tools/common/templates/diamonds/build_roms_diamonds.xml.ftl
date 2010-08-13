<#--
============================================================================ 
Name        : build_roms_diamonds.xml.ftl
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

<#assign db = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader', "${dbPath}") >

    <images>
        <#assign overallStatus = "ok">
        
        <#list db['native:java.lang.String']['select DISTINCT component.component from component where component.component like \'%.fpsx\''] as component>
        <image>
            <#assign status = "ok">
            <#list db['jpa']['select m from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where p.severity=\'ERROR\' and c.component=\'${component}\''] as m>
            <#assign match = m.text?matches(".*?fpsx' - DOESN'T EXIST")>
            <#if match>
            <#assign status = "failed">
            <#assign overallStatus = "failed">
            </#if>
            </#list>
            <status>${status}</status>
            
            <name>${component}</name>
            <hardware>N/A</hardware>
            <#assign type = component?matches("([^.]+)\\.fpsx")[0]>
            <type>${type?groups[1]}</type>
            <errors count="${db['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where p.severity=\'ERROR\' and c.component=\'${component}\''][0]}">
                <#list db['jpa']['select m from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where p.severity=\'ERROR\' and c.component=\'${component}\''] as m>
                <error>${m.text}</error>
                </#list>
            </errors>
            <warnings count="${db['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where p.severity=\'WARNING\' and c.component=\'${component}\''][0]}">
                <#list db['jpa']['select m from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where p.severity=\'WARNING\' and c.component=\'${component}\''] as m>
                <warning>${m.text}</warning>
                </#list>
            </warnings>
        </image>
        </#list>
        
        <status>${overallStatus}</status>
    </images>

<#include "diamonds_footer.ftl">



