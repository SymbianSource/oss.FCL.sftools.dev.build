<#--
============================================================================ 
Name        : whatlog_result.ini.ftl
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
number.of.logs=${table_info['jpasingle']['select count(l.path) path from LogFile l'][0]}
number.of.whatlog.entries=${table_info['jpasingle']['select count(e) from WhatLogEntry e'][0]}


