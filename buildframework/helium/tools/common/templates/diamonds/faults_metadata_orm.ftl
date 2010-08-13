<#--
============================================================================ 
Name        : faults_metadata_orm.ftl 
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

<#setting number_format="0">

    <#assign table_info = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader',
        "${dbPath}") >

    <build>    
        <generated_files>${table_info['jpasingle']['select Count(w.id) from WhatLogEntry w JOIN w.component as c JOIN c.logFile as l where LOWER(l.path) like \'%\\_compile.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_clean\\_%compile.log\' ESCAPE \'\\\''][0]}</generated_files>
    </build>

    <faults>
        <total severity="error">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.severity as p JOIN m.logFile as l where LOWER(l.path) like \'%\\_compile.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_clean\\_%compile.log\' ESCAPE \'\\\' and p.severity=\'ERROR\''][0]}</total>
        <total severity="warning">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.severity as p JOIN m.logFile as l where LOWER(l.path) like \'%\\_compile.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_clean\\_%compile.log\' ESCAPE \'\\\' and p.severity = \'WARNING\''][0]}</total>
        <total severity="warning_rvct_other">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.severity as p JOIN m.logFile as l where LOWER(l.path) like \'%\\_compile.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_clean\\_%compile.log\' ESCAPE \'\\\' and p.severity = \'WARNING\''][0]}</total>
        <!-- todo update to calculate the correct value -->
        <total severity="warning_rvct_bad">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.severity as p JOIN m.logFile as l where LOWER(l.path) like \'%\\_compile.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_clean\\_%compile.log\' ESCAPE \'\\\' and p.severity=\'CRITICAL\''][0]}</total>
    <#list table_info['native:java.lang.String']['select DISTINCT component.component from component INNER JOIN logfile ON logfile.logfile_id=component.logfile_id where logfile.path like \'%_compile.log\' and logfile.path not like \'%\\_clean\\_%compile.log\''] as component>
        <component>
            <name>${component}</name>
            <total severity="error">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where UPPER(p.severity)=\'ERROR\' and c.component=\'${component}\' and LOWER(l.path) like \'%\\_compile.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_clean\\_%compile.log\' ESCAPE \'\\\''][0]}</total>
            <total severity="warning">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where UPPER(p.severity)=\'WARNING\' and c.component=\'${component}\' and LOWER(l.path) like \'%\\_compile.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_clean\\_%compile.log\' ESCAPE \'\\\''][0]}</total>
            <total severity="critical">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where UPPER(p.severity)=\'REMARK\' and c.component=\'${component}\' and LOWER(l.path) like \'%\\_compile.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_clean\\_%compile.log\' ESCAPE \'\\\''][0]}</total>
        </component>
    </#list>
    </faults>

    <!-- all components -->
    <components>
    <#assign components = pp.newWritableSequence()>
    <#list table_info['jpa']['select c from Component c JOIN c.logFile l WHERE l.path like \'%_compile.log\' and l.path not like \'%\\_clean\\_%compile.log\''] as component>
        <#if (!components?seq_contains(component.component))>
        <@pp.add seq=components value=component.component />
        <component>
            <name>${component.component}</name>
            <#if component.sysdefUnit??>
            <package>${component.sysdefUnit.sysdefComponent.sysdefCollection.sysdefPackage.packageId}</package>
            </#if>
        </component>
        </#if>
    </#list>
    </components>
<#include "diamonds_footer.ftl"> 