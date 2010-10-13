<#--
============================================================================ 
Name        : doclet_list.rst.ftl
Part of     : Helium 

Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
=======================
Helium Ant Tasks/ Types
=======================
   
.. contents::

<#assign lastcategory=''/>
<#list doc.jel.jelclass as x>
    <#list x.@superclass as superclass>
        <#assign category=x.@package/>
        <#assign name=x.@type/>
        <#assign t1=''/>
        <#assign t2=''/>
        <#if (superclass?contains('Task') || superclass?contains('Type')) && !x.@abstract[0]??>
            <#list x.comment.attribute as attribute>
                <#list attribute.description?split(' ') as value>
                    <#if value?contains("category=")>
                        <#assign category=value?replace('category=', '')?replace('"', '')/>
                        <#if category != lastcategory>
${category}
=============

                        </#if>
                        <#assign lastcategory=category/>
                    </#if>
                    <#if value?contains("name=")>
                        <#assign name=value?replace('name=', '')?replace('"', '')/>
                    </#if>
                </#list>
            </#list>
<#if superclass?contains('Task')>Task</#if><#if superclass?contains('Type')>Type</#if>: ${name}
----------------------------------------------------------------------------
            <#list x.comment.description as description>
.. raw:: html

    ${description}
            </#list>

<#list x.methods.method as method>
   <#if method.@name?starts_with('set')>
      <#if t1 != 'true'>
      <#assign t1='true'/>
.. csv-table:: Parameters
   :header: "Attribute", "Description", "Required?"
   
      </#if>
   ${method.@name?replace('set', '', 'f')?uncap_first}, <#list method.comment.description as d>"${d?replace('\n', '')}"</#list>,<#list method.comment.attribute as a><#if a.@name?starts_with('@ant')>${(a.@name == '@ant.required')?string}</#if></#list>
   </#if>
</#list>

<#list x.methods.method as method>
   <#if method.@name?starts_with('add') && method["count(params/param)"] == 1>
      <#if t2 != 'true'>
      <#assign t2='true'/>
.. csv-table:: Parameters accepted as nested elements
   :header: "Type", "Description", "Required?"
   
      </#if>
   <#list method.params.param as d>"${d.@type?uncap_first}"</#list>, <#list method.comment.description as d>"${d?replace('\n', '')}"</#list>,<#list method.comment.attribute as a><#if a.@name?starts_with('@ant')>${(a.@name == '@ant.required')?string}</#if></#list>
   </#if>
</#list>

        </#if>
    </#list>
</#list>
