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
component.count=${table_info['jpasingle']['select count(c.id) from Component c'][0]}
<#assign counter=0>
<#list table_info['jpa']['select c from Component c'] as component>
component.${counter}.unit.id=${component.unitId}
component.${counter}.unit.location=<#if component.sysdefUnit??>${component.sysdefUnit.location}</#if>
<#assign counter=counter + 1>
</#list>
