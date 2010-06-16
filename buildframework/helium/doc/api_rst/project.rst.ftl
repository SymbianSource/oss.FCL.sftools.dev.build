<#--
============================================================================ 
Name        : project.rst.ftl
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

<#list doc.antDatabase.project as project>
<@pp.changeOutputFile name="project-${project.name}.rst" />


.. index::
   ${project.name}
    
==========================================================
Project ${project.name}
==========================================================

.. contents::

:Location: <@helium_api_location_path location="${project.location}"/>

<#recurse project.description>

**Project dependencies**

<#assign filelist = project.projectDependency>
<#list filelist as filelistvar>
- ``${filelistvar}``
</#list>

Targets
=========

<#assign targetCache = {}>
<#list project.target as target>
    <#assign targetCache = targetCache + {target.name: target}>
</#list>

<#list targetCache?keys?sort as name>
<#assign target=targetCache[name]>

.. index::
   ${target.name}
  
${target.name}
----------------------------------------------------------

<#if target.deprecated?length &gt; 0>
..warning:: ${target.deprecated}
</#if>

<#if target.description?length &gt; 0>
:Description: ${target.description}
</#if>
:Location: <@helium_api_location_path location="${target.location}"/>
:Scope: ${target.scope}
<#if target.ifDependency?length &gt; 0>
:Condition: Target **is** run if property defined: :hlm-p:`${target.ifDependency}`
</#if>
<#if target.unlessDependency?length &gt; 0>
:Condition: Target **is not** run if property defined: ``${target.unlessDependency}``
</#if>

<#recurse target.documentation>

<#assign propertyList=target.propertyDependency?sort>   
<#if propertyList?size &gt; 0>
**Property dependencies**

<#list propertyList as property>
- :hlm-p:`${property}`
</#list>
</#if>


**Target dependencies**

.. raw:: html

  <img src="../../api/helium/target-${target.name}.dot.png" alt="target-${target.name}" usemap="#target-${target.name}" style="border-style: none"/>
  <map name="target-${target.name}" id="target-${target.name}">
   
.. raw:: html
  :file: ../../api/helium/target-${target.name}.dot.cmap
   
.. raw:: html

  </map>  
  
**Source code**

::

    ${target.source?replace("^", "    ", "rm")}

</#list>


<#if project.property?size &gt; 0>

Properties
===========

<#assign propertyCache = {}>
<#list project.property as property>
    <#assign propertyCache = propertyCache + {property.name: property}>
</#list>

<#list propertyCache?keys?sort as name>
<#assign property=propertyCache[name]>

.. index::
   ${property.name}
   
${property.name}
----------------------------------------------------------

<#if property.deprecated?length &gt; 0>
..warning:: ${property.deprecated}
</#if>

:Location: <@helium_api_location_path location="${property.location}"/>
:Type: ${property.type}
:Scope: ${property.scope}
:Editable: ${property.editable}
<#if property.defaultValue?size &gt; 1>
:Default value: ``${property.defaultValue}``
</#if>

<#recurse property.documentation>

**Source code**

::

    ${property.source}

</#list>
</#if>

<#if project.macro?size &gt; 0>

Macros
===========

<#assign macroCache = {}>
<#list project.macro as macro>
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



