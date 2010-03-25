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
##############################
Helium API Changes
##############################

.. index::
  module: Helium API Changes

.. contents::

This describes API changes between release ${old_release} and release ${new_release}.

Projects added
==============
<#list doc.apiChanges.project?sort as project>
    <#if project.@state == 'added'>
* `${project} <api/helium/project-${project}.html>`_
    </#if>
</#list>

Projects removed
================
<#list doc.apiChanges.project?sort as project>
    <#if project.@state == 'removed'>
* ${project}
    </#if>
</#list>

Targets added
=============
<#list doc.apiChanges.target?sort as target>
    <#if target.@state == 'added'>
* `${target} <api/helium/target-${target}.html>`_
    </#if>
</#list>

Targets removed or made private
===============================
<#list doc.apiChanges.target?sort as target>
    <#if target.@state == 'removed'>
* ${target}
    </#if>
</#list>

Properties added
================
<#list doc.apiChanges.property?sort as property>
    <#if property.@state == 'added'>
* `${property} <api/helium/property-${property}.html>`_
    </#if>
</#list>

Properties removed or made private
==================================
<#list doc.apiChanges.property?sort as property>
    <#if property.@state == 'removed'>
* ${property}
    </#if>
</#list>

Macros added
============
<#list doc.apiChanges.macro?sort as macro>
    <#if macro.@state == 'added'>
* `${macro} <api/helium/macro-${macro}.html>`_
    </#if>
</#list>

Macros removed
==============
<#list doc.apiChanges.macro?sort as macro>
    <#if macro.@state == 'removed'>
* ${macro}
    </#if>
</#list>

Ant Tasks added
===============
<#list doc.apiChanges.taskdef?sort as taskdef>
    <#assign link = taskdef.@classname>
    <#if taskdef.@state == 'added'>
      <#if link?contains("com.nokia.helium")>
* `${taskdef} <helium-antlib/api/doclet/${link}.html>`_
      <#else>          
* `${taskdef} <api/ant/${link}.html>`_
      </#if>
    </#if>  
</#list>

Ant Tasks removed
=================
<#list doc.apiChanges.taskdef?sort as taskdef>
    <#if taskdef.@state == 'removed'>
* ${taskdef}
    </#if>
</#list>