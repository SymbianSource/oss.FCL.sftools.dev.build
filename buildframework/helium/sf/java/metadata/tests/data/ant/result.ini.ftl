<#--
============================================================================ 
Name        : result.ini.ftl
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
<#assign table_info = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader', "${dbPath}") >
number.of.logs=${table_info['jpasingle']['select count(l.path) from LogFile l'][0]}
number.of.components=${table_info['jpasingle']['select count(c.component) from Component c'][0]}
number.of.errors=${table_info['jpasingle']['select count(e.id) from MetadataEntry e JOIN e.severity as p WHERE p.severity=\'ERROR\''][0]}


