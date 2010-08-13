<#--
============================================================================ 
Name        : sysdef_data.ini.ftl 
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
package.count=${table_info['jpasingle']['select count(p.id) from SysdefPackage p'][0]}
collection.count=${table_info['jpasingle']['select count(p.id) from SysdefCollection p'][0]}
component.count=${table_info['jpasingle']['select count(p.id) from SysdefComponent p'][0]}
unit.count=${table_info['jpasingle']['select count(p.id) from SysdefUnit p'][0]}
