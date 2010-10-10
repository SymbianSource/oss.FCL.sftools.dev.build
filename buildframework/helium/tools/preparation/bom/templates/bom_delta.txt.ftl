<#--
============================================================================ 
Name        : bom_delta.txt.ftl 
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
Bill Of Materials
=================

Build from: ${doc.bomDelta.buildFrom}
Build to:   ${doc.bomDelta.buildTo}


Baselines
---------
<#list doc.bomDelta.content.baseline as baseline>
<#if baseline.@status == "added">
+ ${baseline}
</#if>
<#if baseline.@status == "deleted">
- ${baseline}
</#if>
</#list>

Tasks
-----
<#list doc.bomDelta.content.task as task>
<#if task.@status == "added">
+ ${task}
</#if>
<#if task.@status == "deleted">
- ${task}
</#if>
</#list>

