<#--
============================================================================ 
Name        : ca_content_libraries.txt.ftl 
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
<#if (logfilename)??>
    <#assign logfilename_cleaned = "${logfilename}"?replace("\\","/") >
    <#assign table_info = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader',
        "${dbPath}") >
        <#assign logfile = table_info['jpasingle']['select l from LogFile l where LOWER(l.path)=\'${logfilename_cleaned?lower_case}\''][0] >
    <#if (checktype == 'header')>
in header code
        <#list table_info['native:java.lang.String']['select distinct w.member FROM WhatLogEntry w where w.member like \'%/epoc32/include%.%\''] as hfile>
${hfile}
        </#list>
    <#elseif (checktype == 'lib')>
in lib code
        <#list table_info['native:java.lang.String']['select distinct w.member FROM WhatLogEntry w where w.member like \'%.lib\''] as hfile>
${hfile}
        </#list>
        <#list table_info['native:java.lang.String']['select distinct w.member FROM WhatLogEntry w where w.member like \'%.dso\''] as hfile>
${hfile}
        </#list>
    </#if>
</#if>
