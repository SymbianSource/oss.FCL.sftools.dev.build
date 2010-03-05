<#--
============================================================================ 
Name        : macro.ftl 
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
    <#assign convertedLogPath = "${logpath}"?replace("\\","/") >
    <#assign logfile =  table_info['jpasingle']['select l from LogFile l where LOWER(l.path) like \'%${convertedLogPath?lower_case}\''][0]>
   <faults>
        <total severity="error">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.priority as p where m.logPathId=${logfile.id} and p.priority like \'%ERROR%\''][0]}</total>
        <total severity="warning">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.priority as p where m.logPathId=${logfile.id} and UPPER(p.priority) like \'%WARNING%\''][0]}</total>
        <total severity="warning_rvct_other">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.priority as p where m.logPathId=${logfile.id} and UPPER(p.priority) like \'%WARNING%\''][0]}</total>
        <!-- todo update to calculate the correct value -->
        <total severity="warning_rvct_bad">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN  m.priority as p where m.logPathId = ${logfile.id} and UPPER(p.priority) like \'%REMARK%\''][0]}</total>
    <#list table_info['jpa']['select c from Component c where c.logPathID=${logfile.id} ORDER BY c.component'] as component>
        <component>
            <name>${component.component}</name>
            <total severity="error">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.priority as p where UPPER(p.priority) like \'%ERROR%\' and m.componentId = ${component.id}'][0]}</total>
            <total severity="warning">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.priority as p where UPPER(p.priority) like \'%WARNING%\' and m.componentId = ${component.id}'][0]}</total>
            <total severity="critical">${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.priority as p where UPPER(p.priority) like \'%REMARK%\' and m.componentId = ${component.id}'][0]}</total>
        </component>
    </#list>
    </faults>
    <components>
    <#list table_info['jpa']['select c from Component c where c.logPathID=${logfile.id}'] as component>
    <!-- all components -->
        <component>${component.component}</component>
    </#list>
    </components>
<#include "diamonds_footer.ftl"> 