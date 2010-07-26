<#--
============================================================================ 
Name        : bmd.macros.xml.ftl 
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

<#macro helium_scanlog_entry >
    <style type="text/css">
        <#include "log3.css"/>
    </style>
    <script type="text/javascript">
        <#include "expand3.js"/>
    </script>
</#macro>

    <#assign table_info = pp.loadData('com.nokia.helium.metadata.SQLFMPPLoader',
        "${dbPath}") >
<html>
<body>
<h1>Summary</h1>
<table>
<#assign priority_table = table_info['select * from priority'] >
<#assign component_table = table_info['select id, component from component'] >
<#assign logpath_table = table_info['select * from logfiles'] >
<#assign priority_ids = priority_table?keys>
<tr><td>Total&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
<#assign quotes='\'' />
<#list priority_ids as priority>
<td>${priority_table['${priority}']}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
${table_info['select count(data) as COUNT from metadata where priority_id=${priority}'][0]['COUNT']}</td>
</#list>
</tr>
</table>
<h1>Listing based on Priority</h1>
<table>
<#list priority_ids as priority>
<tr><td>priority_id:${priority}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
<tr><td>&nbsp;</td></tr>
<tr><td><h3>${priority_table['${priority}']}</h3></td></tr>

<#list table_info['select * from metadata where priority_id=${priority}'] as recordentry >
<tr><td>logtext:${recordentry['data']}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
<td>lineNo:${recordentry['line_number']}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td></tr>
</#list>
</#list>
</table>
<h1>Listing based on Component</h1>
<table>
<#assign component_ids = component_table?keys>
<#list component_ids as component>
<tr><td>&nbsp;</td></tr>
<tr><td><h3>${component_table['${component}']}</h3></td></tr>
<#list table_info['select * from metadata where component_id=${component} order by priority_id'] as recordentry >
<tr><td>priority:${priority_table["${recordentry['priority_id']}"]}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
<td>logtext:${recordentry['data']}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
<td>lineNo:${recordentry['line_number']}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td></tr>
</#list>
</#list>
</table>
</body>
</html>