<#--
============================================================================ 
Name        : macros_list.rst.ftl
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

=============
Macros list
=============

<#assign macroCache = {}>
<#list doc.antDatabase.project.macro as macro>
    <#assign macroCache = macroCache + {macro.name: macro}>
</#list>
<#list doc.antDatabase.antlib.macro as macro>
    <#assign macroCache = macroCache + {macro.name: macro}>
</#list>

.. csv-table:: Helium macros
   :header: "Macro", "Project/Antlib", "Summary"
   
<#list macroCache?keys?sort as name>
<#assign macro=macroCache[name]>
<#assign prefix = "project">
<#if macro?parent.name?contains("antlib")>
    <#assign prefix = "antlib">
</#if>
    ":hlm-t:`${name}`", "`${macro?parent.name} <${prefix}-${macro?parent.name}.html>`_", "${macro.summary?replace("^", "    ", "rm")?replace("\"", "\"\"", "rm")?trim}"
</#list>


