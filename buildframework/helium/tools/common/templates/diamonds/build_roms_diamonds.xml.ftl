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
        
        <#list db['jpa']['select c from Component c where c.component like \'%.fpsx\''] as component>
        <image>
            <#assign status = "ok">
            <#assign missing =  db['jpasingle']['select Count(m.id) from Component c JOIN c.metadataEntries as m JOIN m.severity as p where c.id=\'${component.id}\' and p.severity=\'ERROR\' and m.text like \'%.fpsx\'\' - DOESN\'\'T EXIST\''][0]>
            <#if (missing > 0)>
            <#assign status = "failed">
            <#assign overallStatus = "failed">
            </#if>
            <status>${status?xml}</status>
            <name>${component.component?xml}</name>
            <hardware>N/A</hardware>
            <#assign type = component.component?matches("([^.]+)\\.fpsx")[0]>
            <type>${type?groups[1]?xml}</type>
            <errors count="${db['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where p.severity=\'ERROR\' and c.id=\'${component.id}\''][0]}">
                <#list db['jpa']['select m from MetadataEntry m JOIN m.severity as p JOIN m.component as c where p.severity=\'ERROR\' and c.id=\'${component.id}\''] as m>
                <error>${m.text?xml}</error>
                </#list>
            </errors>
            <warnings count="${db['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where p.severity=\'WARNING\' and c.id=\'${component.id}\''][0]}">
                <#list db['jpa']['select m from MetadataEntry m JOIN m.severity as p JOIN m.component as c where p.severity=\'WARNING\' and c.id=\'${component.id}\''] as m>
                <warning>${m.text?xml}</warning>
                </#list>
            </warnings>
        </image>
        </#list>
        
        <status>${overallStatus}</status>
    </images>

<#include "diamonds_footer.ftl">



