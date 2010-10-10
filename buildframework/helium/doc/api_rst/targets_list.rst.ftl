<#--
============================================================================ 
Name        : targets_list.rst.ftl
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

=============
Targets list
=============

<#assign targetCache = {}>
<#list doc.antDatabase.project.target as target>
    <#assign targetCache = targetCache + {target.name: target}>
</#list>

.. csv-table:: Helium targets
   :header: "Target", "Project", "Summary"
   
<#list targetCache?keys?sort as name>
<#assign target=targetCache[name]>
    ":hlm-t:`${name}`", "`${target?parent.name} <project-${target?parent.name}.html>`_", "${target.summary?replace("^", "    ", "rm")?replace("\"", "\"\"", "rm")?trim}"
</#list>


