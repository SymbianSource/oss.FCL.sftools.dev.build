<#--
============================================================================ 
Name        : help_text.txt.ftl 
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
<#list xml["//target[name='${helpTarget}']"] as target>

Target ${target.name}:
-----------------------------
Location: ${target.location}

<#if target.description?length &gt; 0>
Description:
${target.description}
</#if>
Documentation:<#recurse target.documentation>

Property dependencies:
<#list target.propertyDependency as property>
* ${property}
</#list>
</#list>

<#macro tt> "<#recurse>" </#macro>

<#macro p>

<#recurse></#macro>

<#macro ul>

<#recurse></#macro>

<#macro li> * <#recurse>
</#macro>

<#macro b><#recurse>*</#macro>

<#macro @text>${.node?trim}</#macro>

