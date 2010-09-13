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
<#assign itemList = xml["//*[name='${helpItem}']"]/>
<#if itemList?size &gt; 0>
<#list itemList as item>

${item.name}
-----------------------------
Location: ${item.location}

<#if (item.description)?has_content>
Description:
${item.description}
</#if>
Documentation:<#recurse item.documentation>

</#list>

<#else>

${helpItem}
Documentation not found.
</#if>


<#macro tt> "<#recurse>" </#macro>

<#macro p>

<#recurse></#macro>

<#macro ul>

<#recurse></#macro>

<#macro li> * <#recurse>
</#macro>

<#macro b><#recurse></#macro>

<#macro @text>${.node?trim}</#macro>

<#macro pre>


    <#recurse></#macro>

