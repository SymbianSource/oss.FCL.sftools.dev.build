<#--
============================================================================ 
Name        : db2xml.xml.ftl 
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
<#assign table_info = pp.loadData('com.nokia.helium.metadata.SQLFMPPLoader', "${dbPath}") >
<?xml version="1.0" encoding="utf-8"?>
<log filename="${log}">
<build>

<#list table_info['select * from metadata INNER JOIN logfiles ON logfiles.id=metadata.logfile_id INNER JOIN severity ON severity.id=metadata.severity_id where severity=\'ERROR\' and path like \'${r\'%\'}${log}\''] as recordentry >
<message severity="error"><![CDATA[${recordentry['data']}]]></message>
</#list>

</build>
</log>