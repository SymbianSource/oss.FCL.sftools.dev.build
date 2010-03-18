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
<#assign totalTargets=0>
<#assign execTargets=0>
<#assign totalTasks=0>
<#assign execTasks=0>
<#list database.antDatabase.project.target as target>
<#if target_has_next == false>
<#assign totalTargets = target_index>
</#if>
<#list target?children as targetElement>
<#if targetElement?node_name == "tasks">
<#assign totalTasks = totalTasks + (targetElement.@@text)?number>
</#if>
</#list>
</#list>
<#list doc.build?children as childElement>
<#if childElement?node_name == "task">
<#list childElement?children as child>
<#if child?node_name == "target">
<@elementFunc element=child/>
</#if>
</#list>
</#if>
</#list>
<#macro elementFunc element>
<#if element?node_name == "target">
<#assign execTargets = execTargets + 1>
<#list element?children as child>
<@elementFunc element=child/>
</#list>
<#elseif element?node_name == "task">
<#assign execTasks = execTasks + 1>
<#list element?children as child>
<@elementFunc element=child/>
</#list>
</#if>
</#macro>
<h2>Ant Code Coverage</h2>
<p>Total Targets: ${totalTargets}</p>
<p>Executed Targets: ${execTargets}</p>
<p>Percentage Targets: <#if totalTargets!=0>${(execTargets/totalTargets*100)?int}<#else>N/A</#if></p>
<p>Total Tasks: ${totalTasks}</p>
<p>Executed Tasks: ${execTasks}</p>
<p>Percentage Tasks: <#if totalTasks!=0>${(execTasks/totalTasks*100)?int}<#else>N/A</#if></p>