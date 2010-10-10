<#--
============================================================================ 
Name        : properties_list.rst.ftl
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

===============
Properties list
===============

<#assign propertyCache = {}>
<#list doc.antDatabase.project.property as property>
    <#assign propertyCache = propertyCache + {property.name: property}>
</#list>

.. csv-table:: Helium properties
   :header: "Property", "Project", "Summary", "Default Value"
   
<#list propertyCache?keys?sort as name>
<#assign property=propertyCache[name]>
    ":hlm-t:`${name}`", "`${property?parent.name} <project-${property?parent.name}.html>`_", "${property.summary?replace("^", "    ", "rm")?replace("\"", "\"\"", "rm")?trim}", "<#if property.defaultValue?length &lt; 25>${property.defaultValue}</#if>"
</#list>


