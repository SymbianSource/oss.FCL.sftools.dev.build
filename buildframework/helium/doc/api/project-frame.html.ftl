<#--
============================================================================ 
Name        : 
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
<#list doc.antDatabase.project as project>
<@pp.changeOutputFile name="project-frame-${project.name}.html" />
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE HTML PUBLIC "-//w3c//dtd xhtml 1.0 strict//en"
      "http://www.w3.org/tr/xhtml1/dtd/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<#include "api.ftllib"/>

<@helium_api_head_section title="Project (Helium API)"/>

<body>
    <table border="0" width="100%" summary="">
    <tr>
        <td style="white-space: nowrap">
            <font size="+1" class="frameheadingfont">Targets</font>&#160;
            <font class="frameitemfont">
            <br/>
    
            <#assign targetlist=project.target.name?sort>
            <#list targetlist as target>
            <a href="target-${target}.html" title="" target="classframe">${target}</a>
            <br/>
            </#list>
            </font>
        </td>
    </tr>
    </table>
</body>

</html>

</#list>