<#--
============================================================================ 
Name        : error.csv.ftl 
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
Component,Errors,Warnings
<#assign table_info = pp.loadData('com.nokia.helium.metadata.SQLFMPPLoader', "${dbPath}") >
<#assign error_table = table_info['select *
FROM ((SELECT data.component AS ecomponent, count(data.line_number) AS ecount
FROM  (SELECT * from component LEFT OUTER JOIN metadata ON component.id=metadata.component_id) AS data, logfiles, priority
WHERE logfiles.id=data.logPath_id and logfiles.path like \'%_compile.log\' and priority.id=data.priority_id and priority.priority=\'ERROR\'
GROUP BY data.component) AS error LEFT OUTER JOIN (SELECT dataw.component AS wcomponent, count(dataw.line_number) AS wcount
FROM  (SELECT * from component LEFT OUTER JOIN metadata ON component.id=metadata.component_id) AS dataw, logfiles, priority
WHERE logfiles.id=dataw.logPath_id and logfiles.path like \'%_compile.log\' and priority.id=dataw.priority_id and priority.priority=\'WARNING\'
GROUP BY dataw.component) AS warning ON error.ecomponent=warning.wcomponent)']>
<#list error_table as row>
${row['ecomponent']},${row['ecount']},${row['wcount']}
</#list>