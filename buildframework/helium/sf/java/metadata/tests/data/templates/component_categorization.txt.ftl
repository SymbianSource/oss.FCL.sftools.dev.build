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
<#setting number_format="0">
<#assign table_info = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader', "${dbPath}") >
<#list table_info['native:java.lang.String']['select DISTINCT component.component from component INNER JOIN logfile ON logfile.logfile_id=component.logfile_id where logfile.path like \'%_compile%.log\' and logfile.path not like \'%_compile_clean%.log\''] as component>
${component}:error:${table_info['jpasingle']['select Count(m.id) from MetadataEntry m JOIN m.logFile as l JOIN m.severity as p JOIN m.component as c where UPPER(p.severity) like \'%ERROR%\' and c.component=\'${component}\' and LOWER(l.path) like \'%\\_compile%.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_compile\\_clean%.log\' ESCAPE \'\\\''][0]}
${component}:whatlog:${table_info['jpasingle']['select Count(w.id) from WhatLogEntry w JOIN w.component as c JOIN c.logFile as l where c.component=\'${component}\' and LOWER(l.path) like \'%\\_compile%.log\' ESCAPE \'\\\' and LOWER(l.path) not like \'%\\_compile\\_clean%.log\' ESCAPE \'\\\''][0]}
</#list>