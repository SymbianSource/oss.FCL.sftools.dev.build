..  ============================================================================ 
    Name        : configuring_features.rst
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

####################
Configuring Helium Features
####################

Introduction
-------------------------------

This describes how to configure the Helium features.

Helium supports a number of features and this sections gives information on how to configure/enable those features.

We could configure features by enabing/disabling repective properties::

    publishing build results into diamonds.
    Publishing build artificats.
    Enabling blocks features.
    Enabling to use dragonfly and many more.

Properties need to be defined for enabling/disabling the features.
-------------------------------------------------------------
<#assign propertyCache = {}>
<#list doc.antDatabase.project.property as property>
    <#assign propertyCache = propertyCache + {property.name: property}>
</#list>
 
.. csv-table:: Feature properties
   :header: "Property name", "Description", "Allowed value", "Deprecated property"
   
<#list propertyCache?keys?sort as name>
<#assign property=propertyCache[name]>
<#if name?ends_with(".enabled")>
    <#assign deprecatedProperty="">
    <#assign deprecatedMessage="">
    <#list propertyCache?keys?sort as propName>
        <#assign deprecatedName=propertyCache[propName]>
        <#if deprecatedName.summary?contains(name) && deprecatedName.summary?contains("deprecated")>
            <#assign deprecatedProperty=":hlm-p:`${propName}`,">
            <#assign deprecatedMessage="${deprecatedName.deprecated}">
        </#if>
    </#list>
    ":hlm-p:`${name}`", "${property.summary?replace("^", "    ", "rm")?replace("\"", "\"\"", "rm")?trim}", "true/false", "${deprecatedProperty}${deprecatedMessage}"
</#if>
</#list>
   
   
   
   


