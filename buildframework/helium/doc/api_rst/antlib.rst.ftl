<#--
============================================================================ 
Name        : antlib.rst.ftl
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
<#include "api.ftllib"/>

<#list doc.antDatabase.antlib as antlib>
<@pp.changeOutputFile name="antlib-${antlib.name}.rst" />


.. index::
   ${antlib.name}
    
==========================================================
Antlib ${antlib.name}
==========================================================

.. contents::

:Location: <@helium_api_location_path location="${antlib.location}"/>

<#if antlib.macro?size &gt; 0>

Macros
===========

<#assign macroCache = {}>
<#list antlib.macro as macro>
    <#assign macroCache = macroCache + {macro.name: macro}>
</#list>

<#list macroCache?keys?sort as name>
<#assign macro=macroCache[name]>

.. index::
   ${macro.name}

${macro.name}
----------------------------------------------------------

<#if macro.deprecated?length &gt; 0>
..warning:: ${macro.deprecated}
</#if>

:Location: <@helium_api_location_path location="${macro.location}"/>
:Scope: ${macro.scope}

<#recurse macro.documentation>

**Usage**

::

    ${macro.usage?replace("^", "    ", "rm")}

**Source code**

::

    ${macro.source?replace("^", "    ", "rm")}

</#list>
</#if>

</#list>



